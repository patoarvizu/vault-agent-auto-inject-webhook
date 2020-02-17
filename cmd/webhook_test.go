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

var initContainerTestAppDeployment = &appsv1.Deployment{
	ObjectMeta: metav1.ObjectMeta{
		Name:      "test-app-init",
		Namespace: "test",
	},
	Spec: appsv1.DeploymentSpec{
		Selector: &metav1.LabelSelector{
			MatchLabels: map[string]string{
				"app": "test-app-init",
			},
		},
		Template: apiv1.PodTemplateSpec{
			ObjectMeta: metav1.ObjectMeta{
				Labels: map[string]string{
					"app": "test-app-init",
				},
				Annotations: map[string]string{
					"vault.patoarvizu.dev/agent-auto-inject": "init-container",
				},
			},
			Spec: apiv1.PodSpec{
				Containers: []apiv1.Container{
					{
						Name:  "test-app-init",
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

var sidecarTestAppDeployment = &appsv1.Deployment{
	ObjectMeta: metav1.ObjectMeta{
		Name:      "test-app-sidecar",
		Namespace: "test",
	},
	Spec: appsv1.DeploymentSpec{
		Selector: &metav1.LabelSelector{
			MatchLabels: map[string]string{
				"app": "test-app-sidecar",
			},
		},
		Template: apiv1.PodTemplateSpec{
			ObjectMeta: metav1.ObjectMeta{
				Labels: map[string]string{
					"app": "test-app-sidecar",
				},
				Annotations: map[string]string{
					"vault.patoarvizu.dev/agent-auto-inject": "sidecar",
				},
			},
			Spec: apiv1.PodSpec{
				Containers: []apiv1.Container{
					{
						Name:  "test-app-sidecar",
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

var clientset *kubernetes.Clientset

func TestMain(m *testing.M) {
	kubeconfig := os.Getenv("KUBECONFIG")
	config, _ := clientcmd.BuildConfigFromFlags("", kubeconfig)
	cs, _ := kubernetes.NewForConfig(config)
	clientset = cs
	exitCode := m.Run()
	deploymentClient := cs.AppsV1().Deployments("test")
	deploymentList, _ := deploymentClient.List(metav1.ListOptions{})
	for _, d := range deploymentList.Items {
		deploymentClient.Delete(d.Name, &metav1.DeleteOptions{})
	}
	os.Exit(exitCode)
}

func TestWebhookInit(t *testing.T) {
	deploymentClient := clientset.AppsV1().Deployments("test")
	deploymentClient.Create(initContainerTestAppDeployment)
	wait.Poll(time.Second, time.Second*10, func() (done bool, err error) {
		podList, _ := clientset.CoreV1().Pods("test").List(metav1.ListOptions{
			LabelSelector: "app=test-app-init",
		})
		if len(podList.Items) > 0 {
			return true, nil
		}
		return false, nil
	})
	podList, _ := clientset.CoreV1().Pods("test").List(metav1.ListOptions{
		LabelSelector: "app=test-app-init",
	})
	pod := podList.Items[0]
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
	deploymentClient := clientset.AppsV1().Deployments("test")
	deploymentClient.Create(sidecarTestAppDeployment)
	wait.Poll(time.Second, time.Second*10, func() (done bool, err error) {
		podList, _ := clientset.CoreV1().Pods("test").List(metav1.ListOptions{
			LabelSelector: "app=test-app-sidecar",
		})
		if len(podList.Items) > 0 {
			return true, nil
		}
		return false, nil
	})
	podList, _ := clientset.CoreV1().Pods("test").List(metav1.ListOptions{
		LabelSelector: "app=test-app-sidecar",
	})
	pod := podList.Items[0]
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
