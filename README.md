# ProjectDiscovery Documentation

<h4 align="center">
    This is the source code for the ProjectDiscovery documentation located at https://docs.projectdiscovery.io
</h4>


<p align="center">
<a href="https://github.com/projectdiscovery/docs/issues"><img src="https://img.shields.io/badge/contributions-welcome-brightgreen.svg?style=flat" /></a>
<a href="https://twitter.com/pdiscoveryio"><img src="https://img.shields.io/twitter/follow/pdiscoveryio.svg?logo=twitter" /></a>
<a href="https://discord.gg/projectdiscovery"><img src="https://img.shields.io/discord/695645237418131507.svg?logo=discord" /></a>
</p>

<p align="center">
  <a href="#development">Development</a> •
  <a href="#deploying">Deploying</a> •
  <a href="https://discord.gg/projectdiscovery">Join Discord</a>
</p>

---

## Development

1. Checkout this repository
1. Install mintlify with `npm i -g mintlify@latest`
1. Run `mintlify dev`

## Deploying 

To build the final product, we have a couple of additional steps:

1. Build the JS Protocol Docs

- `npm install -g jsdoc-to-markdown`
- `./bin/jsdocs.sh`

2. Build the PDCP API reference documentation

- Either download the latest `openapi.yaml` manually or run `./bin/download-api.sh`
- Run `./bin/generate-api.sh` to generate any new API files
- **OR** run `./bin/generate-filtered-api.sh` to generate API docs without internal/admin endpoints

3. Deployment

After those, Mintlify handles the deployment automatically.