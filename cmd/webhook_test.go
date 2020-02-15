package main

import (
	"os"
	"testing"

	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/client-go/kubernetes"
	"k8s.io/client-go/tools/clientcmd"
)

func TestWebhook(t *testing.T) {
	kubeconfig := os.Getenv("KUBECONFIG")
	config, _ := clientcmd.BuildConfigFromFlags("", kubeconfig)
	clientset, _ := kubernetes.NewForConfig(config)
	pods, _ := clientset.CoreV1().Pods("test").List(metav1.ListOptions{
		LabelSelector: "app=test-app",
	})
	pod := pods.Items[0]
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
