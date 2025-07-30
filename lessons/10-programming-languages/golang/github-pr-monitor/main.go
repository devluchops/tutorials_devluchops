package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"net/http"
	"os"
	"time"
)

type PullRequest struct {
	Title  string `json:"title"`
	Number int    `json:"number"`
	User   struct {
		Login string `json:"login"`
	} `json:"user"`
	CreatedAt time.Time `json:"created_at"`
	HtmlURL   string    `json:"html_url"`
	Base      struct {
		Ref string `json:"ref"`
	} `json:"base"`
}

type PRData struct {
	Repo       string
	PR         PullRequest
	TimeOpened string
}

func getEnvOrExit(key string) string {
	v := os.Getenv(key)
	if v == "" {
		fmt.Printf("Falta la variable de entorno %s\n", key)
		os.Exit(1)
	}
	return v
}

func getEnvOptional(key string) string {
	return os.Getenv(key)
}

func main() {
	githubToken := getEnvOrExit("GITHUB_TOKEN")
	githubOrg := getEnvOrExit("ORG_NAME")
	teamsWebhook := getEnvOptional("TEAMS_WEBHOOK")

	repos, err := getRepos(githubToken, githubOrg)
	if err != nil {
		fmt.Println("Error obteniendo repositorios:", err)
		os.Exit(1)
	}

	var report string
	report += fmt.Sprintf("## Pending Pull Requests in organization %s\n\n", githubOrg)
	report += "| Repo | PR | Author | Target Branch | Time Open | Link |\n"
	report += "|------|----|--------|--------------|-----------|------|\n"

	var allPRs []PRData
	validBranches := map[string]bool{
		"development": true,
		"qa":          true,
		"release":     true,
		"main":        true,
		"master":      true, // Incluyo master también por si acaso
	}

	for _, repo := range repos {
		prs, err := getOpenPRs(githubToken, githubOrg, repo)
		if err != nil {
			fmt.Printf("Error obteniendo PRs de %s: %v\n", repo, err)
			continue
		}

		for _, pr := range prs {
			// Filtrar solo PRs hacia las ramas permitidas
			if !validBranches[pr.Base.Ref] {
				continue
			}

			dur := time.Since(pr.CreatedAt).Round(time.Hour)
			report += fmt.Sprintf("| %s | #%d %s | %s | %s | %s | [Ver PR](%s) |\n",
				repo, pr.Number, pr.Title, pr.User.Login, pr.Base.Ref, dur, pr.HtmlURL)

			// Agregar a la lista para Teams
			allPRs = append(allPRs, PRData{
				Repo:       repo,
				PR:         pr,
				TimeOpened: formatDuration(dur),
			})
		}
	}

	// Print the report to the console
	fmt.Println(report)

	// Send to Teams only if the webhook is configured
	if teamsWebhook != "" {
		if err := sendToTeams(teamsWebhook, githubOrg, allPRs); err != nil {
			fmt.Println("Error sending to Teams:", err)
		} else {
			fmt.Println("Report sent to Teams successfully.")
		}
	} else {
		fmt.Println("TEAMS_WEBHOOK not set. Report shown only in console.")
	}
}

func formatDuration(dur time.Duration) string {
	hours := int(dur.Hours())
	days := hours / 24

	if days > 0 {
		return fmt.Sprintf("%d days", days)
	}
	return fmt.Sprintf("%d hours", hours)
}

func getRepos(githubToken, githubOrg string) ([]string, error) {
	client := &http.Client{}
	var repos []string
	page := 1
	for {
		url := fmt.Sprintf("https://api.github.com/orgs/%s/repos?per_page=100&page=%d", githubOrg, page)
		req, _ := http.NewRequest("GET", url, nil)
		req.Header.Set("Authorization", "Bearer "+githubToken)
		req.Header.Set("Accept", "application/vnd.github+json")

		resp, err := client.Do(req)
		if err != nil {
			return nil, err
		}
		defer resp.Body.Close()

		body, _ := ioutil.ReadAll(resp.Body)

		var data []struct {
			Name string `json:"name"`
		}
		if err := json.Unmarshal(body, &data); err != nil {
			return nil, err
		}
		if len(data) == 0 {
			break
		}
		for _, r := range data {
			repos = append(repos, r.Name)
		}
		page++
	}
	return repos, nil
}

func getOpenPRs(githubToken, githubOrg, repo string) ([]PullRequest, error) {
	url := fmt.Sprintf("https://api.github.com/repos/%s/%s/pulls?state=open", githubOrg, repo)
	req, _ := http.NewRequest("GET", url, nil)
	req.Header.Set("Authorization", "Bearer "+githubToken)
	req.Header.Set("Accept", "application/vnd.github+json")

	client := &http.Client{}
	resp, err := client.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	body, _ := ioutil.ReadAll(resp.Body)

	var prs []PullRequest
	if err := json.Unmarshal(body, &prs); err != nil {
		return nil, err
	}

	return prs, nil
}

func sendToTeams(teamsWebhook, githubOrg string, prData []PRData) error {
	card := createAdaptiveCard(githubOrg, prData)

	// Volver al formato simple que funcionaba
	payload := map[string]interface{}{
		"type": "message",
		"attachments": []map[string]interface{}{
			{
				"contentType": "application/vnd.microsoft.card.adaptive",
				"content":     card,
			},
		},
	}

	b, _ := json.Marshal(payload)

	// Print the payload for debugging
	fmt.Println("Payload to Teams:")
	fmt.Println(string(b))

	resp, err := http.Post(teamsWebhook, "application/json", bytes.NewBuffer(b))
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	if resp.StatusCode >= 300 {
		body, _ := ioutil.ReadAll(resp.Body)
		return fmt.Errorf("Teams webhook error: %s", string(body))
	}

	return nil
}

func createAdaptiveCard(githubOrg string, prData []PRData) map[string]interface{} {
	// Card header con Container de ancho completo
	elements := []map[string]interface{}{
		{
			"type": "Container",
			"items": []map[string]interface{}{
				{
					"type":   "TextBlock",
					"text":   fmt.Sprintf("📋 Pending Pull Requests - %s", githubOrg),
					"weight": "Bolder",
					"size":   "Large",
					"color":  "Accent",
					"wrap":   true,
				},
				{
					"type":    "TextBlock",
					"text":    fmt.Sprintf("Total open PRs: %d", len(prData)),
					"weight":  "Lighter",
					"spacing": "None",
					"wrap":    true,
				},
			},
			"style": "emphasis",
		},
	}

	// Group PRs by urgency
	urgent := []PRData{}
	old := []PRData{}
	recent := []PRData{}

	for _, pr := range prData {
		hours := time.Since(pr.PR.CreatedAt).Hours()
		if hours > 24*30 { // More than 30 days
			urgent = append(urgent, pr)
		} else if hours > 24*7 { // More than 7 days
			old = append(old, pr)
		} else {
			recent = append(recent, pr)
		}
	}

	// Urgent PRs section
	if len(urgent) > 0 {
		elements = append(elements, map[string]interface{}{
			"type": "Container",
			"items": []map[string]interface{}{
				{
					"type":    "TextBlock",
					"text":    "🚨 Urgent PRs (+30 days)",
					"weight":  "Bolder",
					"size":    "Medium",
					"color":   "Attention",
					"spacing": "Medium",
					"wrap":    true,
				},
			},
		})

		for _, pr := range urgent {
			elements = append(elements, createPRBlock(pr, "Attention"))
		}
	}

	// Old PRs section
	if len(old) > 0 {
		elements = append(elements, map[string]interface{}{
			"type": "Container",
			"items": []map[string]interface{}{
				{
					"type":    "TextBlock",
					"text":    "⚠️ Old PRs (7-30 days)",
					"weight":  "Bolder",
					"size":    "Medium",
					"color":   "Warning",
					"spacing": "Medium",
					"wrap":    true,
				},
			},
		})

		for _, pr := range old {
			elements = append(elements, createPRBlock(pr, "Warning"))
		}
	}

	// Recent PRs section
	if len(recent) > 0 {
		elements = append(elements, map[string]interface{}{
			"type": "Container",
			"items": []map[string]interface{}{
				{
					"type":    "TextBlock",
					"text":    "✅ Recent PRs (<7 days)",
					"weight":  "Bolder",
					"size":    "Medium",
					"color":   "Good",
					"spacing": "Medium",
					"wrap":    true,
				},
			},
		})

		for _, pr := range recent {
			elements = append(elements, createPRBlock(pr, "Good"))
		}
	}

	return map[string]interface{}{
		"type":    "AdaptiveCard",
		"version": "1.2",
		"body":    elements,
		"$schema": "http://adaptivecards.io/schemas/adaptive-card.json",
		// Configuración específica para Teams para ancho completo
		"msteams": map[string]interface{}{
			"width": "Full",
		},
	}
}

func createPRBlock(pr PRData, colorTheme string) map[string]interface{} {
	// Emoji for each branch type
	branchEmoji := map[string]string{
		"main":        "🚀",
		"master":      "🚀",
		"release":     "📦",
		"qa":          "🧪",
		"development": "🔧",
	}

	emoji, exists := branchEmoji[pr.PR.Base.Ref]
	if !exists {
		emoji = "📝"
	}

	return map[string]interface{}{
		"type":  "Container",
		"style": "emphasis",
		"width": "stretch", // Forzar que el container use todo el ancho
		"items": []map[string]interface{}{
			{
				"type":  "ColumnSet",
				"width": "stretch", // Asegurar que el ColumnSet también se expanda
				"columns": []map[string]interface{}{
					{
						"type":  "Column",
						"width": "stretch", // Mantener stretch para la primera columna
						"items": []map[string]interface{}{
							{
								"type":   "TextBlock",
								"text":   fmt.Sprintf("**%s** #%d", pr.Repo, pr.PR.Number),
								"weight": "Bolder",
								"size":   "Medium",
								"wrap":   true,
							},
							{
								"type":    "TextBlock",
								"text":    pr.PR.Title,
								"wrap":    true,
								"spacing": "None",
								"size":    "Default",
								"weight":  "Default",
							},
							{
								"type":    "TextBlock",
								"text":    fmt.Sprintf("👤 %s • %s %s • ⏰ %s", pr.PR.User.Login, emoji, pr.PR.Base.Ref, pr.TimeOpened),
								"size":    "Small",
								"color":   "Accent",
								"spacing": "None",
								"wrap":    true,
							},
						},
					},
					{
						"type":  "Column",
						"width": "auto",
						"items": []map[string]interface{}{
							{
								"type": "ActionSet",
								"actions": []map[string]interface{}{
									{
										"type":  "Action.OpenUrl",
										"title": "View PR",
										"url":   pr.PR.HtmlURL,
										"style": "positive",
									},
								},
							},
						},
					},
				},
			},
		},
		"spacing":   "Small",
		"separator": true,
	}
}
