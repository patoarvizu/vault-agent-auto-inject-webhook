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
	foundVolume := func() bool {
		for _, v := range pods.Items[0].Spec.Volumes {
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
		for _, c := range pods.Items[0].Spec.Containers {
			if c.Name == "vault-agent" {
				return true
			}
		}
		return false
	}()
	if !foundVaultAgentContainer {
		t.Errorf("Sidecar container 'vault-agent' not found")
	}
}
