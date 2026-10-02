"""Exercise CD's authoritative inline publication policy without GitHub writes."""

import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import textwrap
import unittest

from support import manage


@unittest.skipUnless(shutil.which("node"), "publication policy requires Node")
class PublicationTests(unittest.TestCase):
    def policy(self, scenario):
        source = (
            Path(__file__).resolve().parents[1] / ".github/workflows/cd.yaml"
        ).read_text()
        policy = textwrap.dedent(
            source.split(
                "// PUBLICATION_POLICY_BEGIN: tests exercise this exact inline policy.",
                1,
            )[1].split("// PUBLICATION_POLICY_END", 1)[0]
        )
        with tempfile.TemporaryDirectory(prefix="publication-policy-") as temporary:
            root = Path(temporary)
            script = root / "policy.cjs"
            script.write_text(
                """
const fs = require('node:fs'), path = require('node:path'), crypto = require('node:crypto');
const scenario = process.env.SCENARIO, directory = process.env.ASSET_DIRECTORY;
const tag = process.env.RELEASE_TAG, commit = process.env.EXPECTED_COMMIT;
const names = JSON.parse(process.env.EXPECTED_PROFILES).map(p=>`nvim-offline-${tag}-${p}.tar.gz`).sort();
const hash = b => crypto.createHash('sha256').update(b).digest('hex');
for(const name of names) fs.writeFileSync(path.join(directory,name),Buffer.from(name));
fs.writeFileSync(path.join(directory,'SHA256SUMS'),names.map(n=>`${hash(Buffer.from(n))}  ${n}\\n`).join(''));
const files=[...names,'SHA256SUMS'];
const assets=files.map(name=>({name,digest:'sha256:'+hash(fs.readFileSync(path.join(directory,name))),state:'uploaded'}));
const state={created:false,uploaded:[],published:false,error:null};
let release={id:1,tag_name:tag,target_commitish:commit,prerelease:true,draft:scenario!=='published',assets:scenario==='published'?assets:scenario==='partial'?[assets[0]]:[]};
if(scenario==='changed') {release.draft=false; release.assets=assets; release.assets[0].digest='sha256:bad';}
if(scenario==='wrong-commit') release.target_commitish='c'.repeat(40);
if(scenario==='missing') fs.unlinkSync(path.join(directory,names[0]));
if(scenario==='bad-checksum') fs.appendFileSync(path.join(directory,'SHA256SUMS'),'bad');
let reads=0;
const context={repo:{owner:'fixture',repo:'fixture'}};
const github={rest:{git:{getRef:async()=>({data:{object:{sha:scenario==='moved'||(scenario==='moved-during'&&++reads>1)?'c'.repeat(40):process.env.EXPECTED_REF_SHA}}})},repos:{
 getReleaseByTag:async()=>{if(scenario==='fresh'||release.draft) {const error=new Error('missing'); error.status=404; throw error;} return {data:release};},
 listReleases:async()=>({data:scenario==='fresh'?[]:scenario==='ambiguous'?[release,{...release,id:2}]:[release]}),
 createRelease:async options=>{state.created=true; release={...options,id:1,assets:[]}; return {data:release};},
 uploadReleaseAsset:async options=>{if(scenario==='upload-failure'&&state.uploaded.length===1) throw new Error('upload failed');
  state.uploaded.push(options.name); const asset={name:options.name,state:'uploaded',digest:'sha256:'+hash(options.data)};
  release.assets.push(asset); return {data:asset};},
 updateRelease:async options=>{state.published=true; release.draft=options.draft; return {data:release};}
}}};
github.paginate=async(method,options)=>(await method(options)).data;
async function publish(){
"""
                + policy
                + """
}
publish().catch(error=>{state.error=String(error);}).finally(()=>{state.draft=release.draft;state.prerelease=release.prerelease;console.log(JSON.stringify(state));});
"""
            )
            env = dict(
                os.environ,
                RELEASE_TAG="v1.2.3-test",
                EXPECTED_COMMIT="a" * 40,
                EXPECTED_REF_SHA="b" * 40,
                EXPECTED_PROFILES=json.dumps(
                    [entry["profile"] for entry in manage.runtime_policy()["archives"]]
                ),
                ASSET_DIRECTORY=str(root / "assets"),
                SCENARIO=scenario,
            )
            (root / "assets").mkdir()
            node = shutil.which("node")
            if node is None:
                self.skipTest("Node runtime unavailable")
            result = subprocess.run(
                [node, str(script)],
                env=env,
                text=True,
                capture_output=True,
                timeout=20,
            )
            self.assertEqual(result.returncode, 0, result.stderr)
            return json.loads(result.stdout)

    def test_new_release_requires_every_profile_and_checksums_before_publication(self):
        result = self.policy("fresh")
        self.assertIsNone(result["error"])
        self.assertTrue(result["created"])
        self.assertEqual(len(result["uploaded"]), len(manage.ARCHIVE_PROFILES) + 1)
        self.assertTrue(result["published"])
        self.assertFalse(result["draft"])

    def test_identical_published_rerun_is_read_only(self):
        result = self.policy("published")
        self.assertIsNone(result["error"])
        self.assertEqual(result["uploaded"], [])
        self.assertFalse(result["published"])
        self.assertTrue(result["prerelease"])

    def test_partial_draft_resumes_only_missing_matching_files(self):
        result = self.policy("partial")
        self.assertIsNone(result["error"])
        self.assertEqual(len(result["uploaded"]), len(manage.ARCHIVE_PROFILES))
        self.assertTrue(result["published"])
        self.assertTrue(result["prerelease"])

    def test_invalid_inputs_and_existing_identity_block_all_writes(self):
        for scenario in (
            "missing",
            "bad-checksum",
            "moved",
            "wrong-commit",
            "changed",
            "ambiguous",
        ):
            with self.subTest(scenario=scenario):
                result = self.policy(scenario)
                self.assertIsNotNone(result["error"])
                self.assertFalse(result["created"])
                self.assertEqual(result["uploaded"], [])
                self.assertFalse(result["published"])

    def test_failed_upload_or_moved_tag_keeps_draft(self):
        for scenario in ("upload-failure", "moved-during"):
            with self.subTest(scenario=scenario):
                result = self.policy(scenario)
                self.assertIsNotNone(result["error"])
                self.assertTrue(result["uploaded"])
                self.assertTrue(result["draft"])
                self.assertFalse(result["published"])
