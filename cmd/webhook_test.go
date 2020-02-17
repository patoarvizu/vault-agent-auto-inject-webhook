package main

import (
	"os"
	"testing"
	"time"

	appsv1 "k8s.io/api/apps/v1"
	apiv1 "k8s.io/api/core/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/util/wait"
	"k8s.io/client-go/kubernetes"
	"k8s.io/client-go/tools/clientcmd"
)

var baseTestAppDeployment = &appsv1.Deployment{
	ObjectMeta: metav1.ObjectMeta{
		Namespace: "test",
	},
	Spec: appsv1.DeploymentSpec{
		Selector: &metav1.LabelSelector{
			MatchLabels: map[string]string{},
		},
		Template: apiv1.PodTemplateSpec{
			ObjectMeta: metav1.ObjectMeta{},
			Spec: apiv1.PodSpec{
				Containers: []apiv1.Container{
					{
						Image: "alpine",
						Command: []string{
							"sh",
							"-c",
							"while true; do sleep 5; done",
						},
					},
				},
			},
		},
	},
}

var overrideConfigMap = &apiv1.ConfigMap{
	ObjectMeta: metav1.ObjectMeta{
		Name:      "override-vault-agent-config",
		Namespace: "test",
	},
	Data: map[string]string{
		"vault-agent-config.hcl": "vault {}",
	},
}

var clientset *kubernetes.Clientset

func createTestAppDeployment(name string, mode string, extraAnnotations map[string]string) *appsv1.Deployment {
	testAppDeployment := baseTestAppDeployment
	nameMode := name + "-" + mode
	testAppDeployment.ObjectMeta.Name = nameMode
	testAppDeployment.Spec.Selector.MatchLabels = map[string]string{"app": nameMode}
	testAppDeployment.Spec.Template.ObjectMeta.Labels = map[string]string{"app": nameMode}
	annotations := map[string]string{"vault.patoarvizu.dev/agent-auto-inject": mode}
	for k, v := range extraAnnotations {
		annotations[k] = v
	}
	testAppDeployment.Spec.Template.ObjectMeta.Annotations = annotations
	testAppDeployment.Spec.Template.Spec.Containers[0].Name = nameMode
	return testAppDeployment
}

func deployTestAppAndWait(deployment *appsv1.Deployment) (pod *apiv1.Pod, e error) {
	deploymentClient := clientset.AppsV1().Deployments(deployment.ObjectMeta.Namespace)
	_, err := deploymentClient.Create(deployment)
	if err != nil {
		return nil, err
	}
	err = wait.Poll(time.Second, time.Second*10, func() (done bool, err error) {
		podList, _ := clientset.CoreV1().Pods(deployment.ObjectMeta.Namespace).List(metav1.ListOptions{
			LabelSelector: "app=" + deployment.ObjectMeta.Name,
		})
		if len(podList.Items) > 0 {
			return true, nil
		}
		return false, nil
	})
	if err != nil {
		return nil, err
	}
	podList, err := clientset.CoreV1().Pods(deployment.ObjectMeta.Namespace).List(metav1.ListOptions{
		LabelSelector: "app=" + deployment.ObjectMeta.Name,
	})
	if err != nil {
		return nil, err
	}
	return &podList.Items[0], nil
}

func TestMain(m *testing.M) {
	kubeconfig := os.Getenv("KUBECONFIG")
	config, _ := clientcmd.BuildConfigFromFlags("", kubeconfig)
	cs, _ := kubernetes.NewForConfig(config)
	clientset = cs
	exitCode := m.Run()
	deploymentClient := cs.AppsV1().Deployments("test")
	deploymentList, _ := deploymentClient.List(metav1.ListOptions{})
	dpb := metav1.DeletePropagationBackground
	for _, d := range deploymentList.Items {
		deploymentClient.Delete(d.Name, &metav1.DeleteOptions{PropagationPolicy: &dpb})
	}
	configMapClient := clientset.CoreV1().ConfigMaps("test")
	configMapClient.Delete(overrideConfigMap.ObjectMeta.Name, &metav1.DeleteOptions{})
	os.Exit(exitCode)
}

func TestOverwriteAgentConfig(t *testing.T) {
	configMapClient := clientset.CoreV1().ConfigMaps("test")
	configMapClient.Create(overrideConfigMap)
	deployment := createTestAppDeployment("test-app-override", "init-container", map[string]string{"vault.patoarvizu.dev/agent-config-map": "override-vault-agent-config"})
	pod, err := deployTestAppAndWait(deployment)
	if err != nil {
		t.Errorf("Error: %v", err)
	}
	volumeFound := false
	for _, v := range pod.Spec.Volumes {
		if v.ConfigMap != nil && v.ConfigMap.Name == "override-vault-agent-config" {
			volumeFound = true
		}
	}
	if !volumeFound {
		t.Error("Volume 'override-vault-agent-config' is not found")
	}
	volumeMountFound := false
	for _, i := range pod.Spec.InitContainers {
		if i.Name != "config-template" {
			continue
		}
		for _, m := range i.VolumeMounts {
			if m.Name == "vault-config-template" {
				volumeMountFound = true
			}
		}
	}
	if !volumeMountFound {
		t.Error("Volume mount 'vault-config-template' is not found")
	}
}

func TestWebhookInit(t *testing.T) {
	deployment := createTestAppDeployment("test-app-init-container", "init-container", nil)
	pod, err := deployTestAppAndWait(deployment)
	if err != nil {
		t.Errorf("Error: %v", err)
	}
	foundVaultAgentInitContainer := func() bool {
		for _, i := range pod.Spec.InitContainers {
			if i.Name == "vault-agent" {
				return true
			}
		}
		return false
	}()
	if !foundVaultAgentInitContainer {
		t.Errorf("Init container 'vault-agent' wasn't injected when agent-auto-inject annotation is 'init-cintainer'")
	}
}

func TestWebhookSidecar(t *testing.T) {
	deployment := createTestAppDeployment("test-app-sidecar", "sidecar", nil)
	pod, err := deployTestAppAndWait(deployment)
	if err != nil {
		t.Errorf("Error: %v", err)
	}
	foundVolume := func() bool {
		for _, v := range pod.Spec.Volumes {
			if v.Name == "vault-tls" {
				return true
			}
		}
		return false
	}()
	if !foundVolume {
		t.Errorf("Volume 'vault-tls' not found")
	}
	foundVaultAgentContainer := func() bool {
		for _, c := range pod.Spec.Containers {
			if c.Name == "vault-agent" {
				return true
			}
		}
		return false
	}()
	if !foundVaultAgentContainer {
		t.Errorf("Sidecar container 'vault-agent' not found")
	}
	foundCaCertVolumeMount := func() bool {
		for _, c := range pod.Spec.Containers {
			if c.Name == "vault-agent" {
				for _, m := range c.VolumeMounts {
					if m.Name == "vault-tls" {
						return true
					}
				}
			}
		}
		return false
	}()
	if !foundCaCertVolumeMount {
		t.Errorf("Volume mount 'vault-tls' for sidecar container not found")
	}
	foundConfigTemplateInitContainer := func() bool {
		for _, i := range pod.Spec.InitContainers {
			if i.Name == "config-template" {
				return true
			}
		}
		return false
	}()
	if !foundConfigTemplateInitContainer {
		t.Errorf("Init container 'config-template' not found")
	}
	foundVaultAddrEnvironmentVariable := func() bool {
		foundInAllContainers := true
		for _, c := range pod.Spec.Containers {
			found := false
			if c.Name == "vault-agent" {
				continue
			}
			for _, e := range c.Env {
				if e.Name == "VAULT_ADDR" {
					found = true
				}
			}
			foundInAllContainers = foundInAllContainers && found
		}
		return foundInAllContainers
	}()
	if !foundVaultAddrEnvironmentVariable {
		t.Errorf("Environment variable 'VAULT_ADDR' not found")
	}
}
