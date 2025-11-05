# Terraform MCP Server - OpenShift Deployment

This directory contains OpenShift deployment manifests for the Terraform MCP Server.

## Prerequisites

1. OpenShift CLI (`oc`) installed and configured
2. Access to the `ocp-mcp-server` namespace
3. Docker image built and pushed to the OpenShift internal registry

## Files

- `deployment.yaml` - Deployment configuration
- `service.yaml` - Service to expose the application internally
- `route.yaml` - OpenShift Route to expose the application externally
- `configmap.yaml` - Configuration values (non-sensitive)
- `secret.yaml` - Template for secrets (sensitive data like TFE_TOKEN)

## Deployment Steps

### 1. Build and Push Docker Image

First, build the Docker image and push it to the OpenShift internal registry:

```bash
# Login to OpenShift
oc login <your-openshift-cluster>

# Get the internal registry route
export REGISTRY=$(oc get route default-route -n openshift-image-registry --template='{{ .spec.host }}')

# Login to the registry
oc whoami -t | docker login -u $(oc whoami) --password-stdin $REGISTRY

# Build the image
cd /path/to/terraform-mcp-server
docker build -t $REGISTRY/ocp-mcp-server/terraform-mcp-server:latest .

# Push the image
docker push $REGISTRY/ocp-mcp-server/terraform-mcp-server:latest
```

Alternatively, you can use OpenShift's BuildConfig for automated builds.

### 2. Create the Secret

Create the secret with your Terraform Enterprise token:

```bash
oc create secret generic terraform-mcp-server-secrets \
  --from-literal=tfe-token=YOUR_TFE_TOKEN_HERE \
  -n ocp-mcp-server
```

Or edit the secret after creation:

```bash
oc edit secret terraform-mcp-server-secrets -n ocp-mcp-server
```

### 3. Update ConfigMap (Optional)

Edit the ConfigMap to customize settings:

```bash
oc edit configmap terraform-mcp-server-config -n ocp-mcp-server
```

Or apply the default ConfigMap:

```bash
oc apply -f openshift/configmap.yaml
```

### 4. Deploy the Application

Deploy all resources:

```bash
oc apply -f openshift/deployment.yaml
oc apply -f openshift/service.yaml
oc apply -f openshift/route.yaml
```

Or apply all at once:

```bash
oc apply -f openshift/
```

### 5. Verify Deployment

Check the deployment status:

```bash
oc get deployment terraform-mcp-server -n ocp-mcp-server
oc get pods -l app=terraform-mcp-server -n ocp-mcp-server
oc get service terraform-mcp-server -n ocp-mcp-server
oc get route terraform-mcp-server -n ocp-mcp-server
```

Check logs:

```bash
oc logs -l app=terraform-mcp-server -n ocp-mcp-server
```

### 6. Test the Health Endpoint

Get the route URL:

```bash
ROUTE_URL=$(oc get route terraform-mcp-server -n ocp-mcp-server -o jsonpath='{.spec.host}')
echo "Route URL: https://$ROUTE_URL"
```

Test the health endpoint:

```bash
curl https://$ROUTE_URL/health
```

The MCP endpoint will be available at:

```bash
curl https://$ROUTE_URL/mcp
```

**Current Deployment:**
- Route URL: `https://terraform-mcp-server-ocp-mcp-server.apps.cluster-nngf2.dynamic.redhatworkshops.io`
- Health Endpoint: `https://terraform-mcp-server-ocp-mcp-server.apps.cluster-nngf2.dynamic.redhatworkshops.io/health`
- MCP Endpoint: `https://terraform-mcp-server-ocp-mcp-server.apps.cluster-nngf2.dynamic.redhatworkshops.io/mcp`

## Configuration

### Environment Variables

The deployment uses a ConfigMap for non-sensitive configuration and a Secret for sensitive data:

- **ConfigMap** (`terraform-mcp-server-config`): Contains settings like TFE_ADDRESS, CORS settings, rate limits, etc.
- **Secret** (`terraform-mcp-server-secrets`): Contains TFE_TOKEN

### Updating Configuration

To update the configuration:

```bash
# Update ConfigMap
oc edit configmap terraform-mcp-server-config -n ocp-mcp-server

# Update Secret
oc edit secret terraform-mcp-server-secrets -n ocp-mcp-server

# Restart pods to pick up changes
oc rollout restart deployment/terraform-mcp-server -n ocp-mcp-server
```

## Troubleshooting

### Check Pod Status

```bash
oc get pods -l app=terraform-mcp-server -n ocp-mcp-server
oc describe pod <pod-name> -n ocp-mcp-server
```

### Check Logs

```bash
oc logs -l app=terraform-mcp-server -n ocp-mcp-server
oc logs -l app=terraform-mcp-server -n ocp-mcp-server --previous
```

### Check Events

```bash
oc get events -n ocp-mcp-server --sort-by='.lastTimestamp'
```

### Check Resource Usage

```bash
oc top pod -l app=terraform-mcp-server -n ocp-mcp-server
```

## Security Considerations

1. **TLS**: The Route uses edge termination with TLS. Ensure your certificates are valid.
2. **CORS**: Configure `MCP_ALLOWED_ORIGINS` in the ConfigMap to restrict access.
3. **Secrets**: Never commit secrets to version control. Use OpenShift Secrets or external secret management.
4. **Network Policies**: Consider adding NetworkPolicies to restrict network access.

## Scaling

To scale the deployment:

```bash
oc scale deployment terraform-mcp-server --replicas=3 -n ocp-mcp-server
```

Note: When using stateful session mode, ensure your load balancer supports session affinity.

