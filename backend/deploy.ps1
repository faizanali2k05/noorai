# Deploy the NoorAI backend to Cloud Run with the realtime OpenAI key.
#
# Usage (from the backend/ folder):
#   ./deploy.ps1 -OpenAiKey "sk-proj-..."
#
# The .env file is excluded from the image (.dockerignore), so the key is
# injected as a Cloud Run environment variable instead of being baked in.

param(
    [Parameter(Mandatory = $true)][string]$OpenAiKey,
    [string]$Service = "noorai-backend",
    [string]$Region = "asia-south1",
    [string]$Model = "gpt-4o-mini"
)

gcloud run deploy $Service `
    --source . `
    --region $Region `
    --allow-unauthenticated `
    --set-env-vars "OPENAI_API_KEY=$OpenAiKey,OPENAI_MODEL=$Model,NOORAI_OFFLINE_MODE=0"

Write-Host ""
Write-Host "After deploy, verify realtime OpenAI is active:" -ForegroundColor Green
Write-Host "  curl https://$Service-485583022901.$Region.run.app/api/health"
