import chokidar from 'chokidar';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const META_DIR = path.resolve(__dirname, '..');
const ROOT_DIR = path.resolve(META_DIR, '..');
const SPECS_DIR = path.join(META_DIR, 'specs');
const STAGES_DIR = path.join(META_DIR, 'stages');
const DECISIONS_DIR = path.join(META_DIR, 'decisions');
const TROUBLESHOOTING_DIR = path.join(META_DIR, 'troubleshooting');
const EXPLAINERS_DIR = path.join(META_DIR, 'explainers');

// 인덱스를 업데이트할 대상 파일들 (루트 기준)
const TARGET_FILES = [
  'CLAUDE.md',
  'AGENT.md',
  'GEMINI.md',
];

// h1, h2, h3 헤딩 추출
function extractHeadings(filePath, maxLevel = 3) {
  try {
    const content = fs.readFileSync(filePath, 'utf-8');
    const lines = content.split('\n');
    const headings = [];

    for (const line of lines) {
      const h1Match = line.match(/^# (.+)$/);
      const h2Match = line.match(/^## (.+)$/);
      const h3Match = line.match(/^### (.+)$/);

      if (h1Match) {
        headings.push({ level: 1, text: h1Match[1].trim() });
      } else if (h2Match && maxLevel >= 2) {
        headings.push({ level: 2, text: h2Match[1].trim() });
      } else if (h3Match && maxLevel >= 3) {
        headings.push({ level: 3, text: h3Match[1].trim() });
      }
    }

    return headings;
  } catch {
    return [];
  }
}

// 디렉토리 내 md 파일 목록 (__template__ 제외)
function getMdFiles(dir) {
  try {
    if (!fs.existsSync(dir)) return [];
    return fs.readdirSync(dir)
      .filter(f => f.endsWith('.md') && !f.startsWith('__'))
      .sort();
  } catch {
    return [];
  }
}

// Specs Index 생성 (h1~h3 TOC)
function buildSpecsIndex() {
  const files = getMdFiles(SPECS_DIR);
  if (files.length === 0) return '';

  let index = '## Specs Index\n\n';
  for (const file of files) {
    const name = file.replace('.md', '');
    const filePath = path.join(SPECS_DIR, file);
    const headings = extractHeadings(filePath, 3);

    index += `- [${name}](./_meta/specs/${file})\n`;
    for (const h of headings) {
      const indent = h.level === 1 ? '  ' : h.level === 2 ? '    ' : '      ';
      index += `${indent}- ${h.text}\n`;
    }
  }
  return index;
}

// Stages Index 생성 (h1~h3 TOC)
function buildStagesIndex() {
  const files = getMdFiles(STAGES_DIR);
  if (files.length === 0) return '';

  let index = '## Stages Index\n\n';
  for (const file of files) {
    const name = file.replace('.md', '');
    const filePath = path.join(STAGES_DIR, file);
    const headings = extractHeadings(filePath, 3);

    index += `- [${name}](./_meta/stages/${file})\n`;
    for (const h of headings) {
      const indent = h.level === 1 ? '  ' : h.level === 2 ? '    ' : '      ';
      index += `${indent}- ${h.text}\n`;
    }
  }
  return index;
}

// Decisions Index 생성 (파일명만)
function buildDecisionsIndex() {
  const files = getMdFiles(DECISIONS_DIR);
  if (files.length === 0) return '';

  let index = '## Decisions Index\n\n';
  for (const file of files) {
    const name = file.replace('.md', '');
    index += `- [${name}](./_meta/decisions/${file})\n`;
  }
  return index;
}

// Troubleshooting Index 생성 (파일명만)
function buildTroubleshootingIndex() {
  const files = getMdFiles(TROUBLESHOOTING_DIR);
  if (files.length === 0) return '';

  let index = '## Troubleshooting Index\n\n';
  for (const file of files) {
    const name = file.replace('.md', '');
    index += `- [${name}](./_meta/troubleshooting/${file})\n`;
  }
  return index;
}

// Explainers Index 생성 (파일명만)
function buildExplainersIndex() {
  const files = getMdFiles(EXPLAINERS_DIR);
  if (files.length === 0) return '';

  let index = '## Explainers Index\n\n';
  for (const file of files) {
    const name = file.replace('.md', '');
    index += `- [${name}](./_meta/explainers/${file})\n`;
  }
  return index;
}

// 단일 파일 인덱스 업데이트
function updateTargetFile(filePath) {
  try {
    if (!fs.existsSync(filePath)) return false;

    let content = fs.readFileSync(filePath, 'utf-8');

    // 마지막 --- 이후 부분을 찾아서 인덱스로 교체
    const separator = '---\n';
    const sepIndex = content.lastIndexOf(separator);

    if (sepIndex !== -1) {
      content = content.substring(0, sepIndex + separator.length);
    }

    // 순서: Specs → Stages → Decisions → Troubleshooting → Explainers
    const specsIndex = buildSpecsIndex();
    const stagesIndex = buildStagesIndex();
    const decisionsIndex = buildDecisionsIndex();
    const troubleshootingIndex = buildTroubleshootingIndex();
    const explainersIndex = buildExplainersIndex();

    let newContent = content + '\n';
    if (specsIndex) {
      newContent += specsIndex + '\n';
    }
    if (stagesIndex) {
      newContent += stagesIndex + '\n';
    }
    if (decisionsIndex) {
      newContent += decisionsIndex + '\n';
    }
    if (troubleshootingIndex) {
      newContent += troubleshootingIndex + '\n';
    }
    if (explainersIndex) {
      newContent += explainersIndex;
    }

    fs.writeFileSync(filePath, newContent.trimEnd() + '\n');
    return true;
  } catch {
    return false;
  }
}

// 모든 대상 파일 업데이트
function updateAllTargets() {
  const updated = [];
  const skipped = [];

  for (const file of TARGET_FILES) {
    const filePath = path.join(ROOT_DIR, file);
    if (updateTargetFile(filePath)) {
      updated.push(file);
    } else {
      skipped.push(file);
    }
  }

  const timestamp = new Date().toLocaleTimeString();
  if (updated.length > 0) {
    console.log(`[${timestamp}] 업데이트: ${updated.join(', ')}`);
  }
  if (skipped.length > 0) {
    console.log(`[${timestamp}] 스킵 (파일 없음): ${skipped.join(', ')}`);
  }
}

// 초기 실행
console.log('Meta Server 시작...');
console.log(`감시 대상: specs/, stages/, decisions/, troubleshooting/, explainers/`);
console.log(`인덱스 대상: ${TARGET_FILES.join(', ')}`);
updateAllTargets();

// Watch 모드
if (process.argv.includes('--watch')) {
  const watcher = chokidar.watch([SPECS_DIR, STAGES_DIR, DECISIONS_DIR, TROUBLESHOOTING_DIR, EXPLAINERS_DIR], {
    ignored: /(^|[\/\\])\../,
    persistent: true,
    ignoreInitial: true
  });

  watcher
    .on('add', (p) => {
      console.log(`파일 추가: ${path.basename(p)}`);
      updateAllTargets();
    })
    .on('unlink', (p) => {
      console.log(`파일 삭제: ${path.basename(p)}`);
      updateAllTargets();
    })
    .on('change', (p) => {
      // specs, stages 파일 내용 변경 시 업데이트 (TOC 갱신 위해)
      if (p.includes('specs') || p.includes('stages')) {
        console.log(`파일 변경: ${path.basename(p)}`);
        updateAllTargets();
      }
    });

  console.log('Watch 모드 활성화. Ctrl+C로 종료.');
} else {
  console.log('단일 실행 완료. --watch 옵션으로 감시 모드 실행 가능.');
}
