// Update the README file with the list of services in this repository.
// A service is a folder that contains a docker-compose.yml file.
// The README file is updated with the list of services.

const fs = require('fs');
const path = require('path');

const services = fs.readdirSync(__dirname);

const readme = fs.readFileSync(path.join(__dirname, 'README.md'), 'utf8');
const start = readme.indexOf('<!-- START SERVICES -->');
const end = readme.indexOf('<!-- END SERVICES -->');

const buildDockerComposeFilePath = (service) =>
  path.join(__dirname, service, 'docker-compose.yml');

const servicesList = services
  .filter((service) => fs.existsSync(buildDockerComposeFilePath(service)))
  .map((service) => {
    // Convert to title case
    const title = service
      .replace(/-/g, ' ')
      .replace(/\b\w/g, (char) => char.toUpperCase());

    return `- ${title}`;
  })
  .join('\n');

const newReadme =
  readme.substring(0, start + 24) + servicesList + '\n' + readme.substring(end);

fs.writeFileSync(path.join(__dirname, 'README.md'), newReadme);

console.log('README updated');
