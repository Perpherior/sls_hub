const path = require("path")
const optimist = require('optimist')
const yaml = require("yaml-boost")

const config = yaml.load(path.join(__dirname, "config/serverless.yml"), optimist.argv)
const stage = optimist.argv.stage ? optimist.argv.stage : "dev"

const layerName = config.service.charAt(0).toUpperCase() + config.service.slice(1) + stage.charAt(0).toUpperCase() + stage.slice(1)
const layerStackName = config.service + "-layer-" + stage

let targetConfig

if(optimist.argv["stack"] == "layer") {
  let layers = {}

  layers[layerName] = {
    path: "layer",
    description: "Ruby project layer",
    compatibleRuntimes: ["ruby2.5"]
  }
  delete config.provider.environment

  targetConfig = {
    service: config.service + "-layer",
    provider: config.provider,
    layers: layers,
    package: {
      include: ["layer/**"]
    }
  }

} else {
  let layerArn = `\${cf:${layerStackName}.` + `${layerName}LambdaLayerQualifiedArn}`.replace(/-/g, 'Dash')

  if(config.custom) {
    config.custom["layerArn"] = layerArn
  } else {
    config.custom = {
      layerArn: layerArn
    }
  }

  targetConfig = config
}

if(process.env.CI){
  if(targetConfig.custom) {
    delete targetConfig.custom.settings
  }
} else {
  targetConfig.provider["profile"] = "devhub-" + stage
}

module.exports = targetConfig
