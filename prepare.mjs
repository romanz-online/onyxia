import { exec } from 'child_process';
import { promisify } from 'util';
import { writeFile } from 'fs/promises';

const getDeployUrl = async (branch, site) => {
  const { stdout } = await promisify(exec)(
    `firebase hosting:channel:list --json --site ${site}`,
    { env: { ...process.env, FIREBASE_TOKEN: process.env.FIREBASE_TOKEN } }
  );
  const { result } = JSON.parse(stdout);
  return result.channels.find(deploy => deploy.name.split('/').pop() === branch)?.url;
};

const generateBranchDeployUrl = async (branch, site) => {
  const { stdout } = await promisify(exec)(
    `firebase hosting:channel:create ${branch} --json --site ${site} --expires 5d`,
    { env: { ...process.env, FIREBASE_TOKEN: process.env.FIREBASE_TOKEN } }
  );
  const { result } = JSON.parse(stdout);
  return result.url;
};

const setEnv = async (url) => {
  const envs = { MY_DEPLOYED_URL: url };
  const stringified = Object.entries(envs).reduce((prev, [key, value]) => `${prev}${key}=${value}\n`, '');
  await writeFile('build.env', stringified);
};

const prepare = async (branch, site) => {
  let url = await getDeployUrl(branch, site);
  if (!url) {
    url = await generateBranchDeployUrl(branch, site);
  }
  await setEnv(url);
  console.log(`preparation complete for ${branch} on site ${site}: ${url}`);
};

const branch = process.argv[2] || process.env.CI_COMMIT_REF_SLUG;
const site = process.argv[3] || process.env.FIREBASE_SITE;

if (!site) {
  console.error('Error: FIREBASE_SITE environment variable or site argument is required');
  process.exit(1);
}

prepare(branch, site).catch(e => {
  console.error(e);
  process.exit(1);
});