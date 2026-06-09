// ===== Chapter Data =====
const CHAPTERS = [
    {
        id: '01_qe_basics',
        number: 1,
        title: '量子ESPRESSO入门与DFT基础',
        stars: '⭐',
        desc: 'DFT理论概述、QE软件架构、输入文件结构、第一个SCF计算',
        keywords: ['DFT', 'Kohn-Sham', 'pw.x', 'namelist', 'SCF']
    },
    {
        id: '02_plane_waves_pseudopotentials',
        number: 2,
        title: '平面波基组与赝势',
        stars: '⭐',
        desc: '平面波展开、截断能收敛性测试、NC/USPP/PAW赝势',
        keywords: ['平面波', 'ecutwfc', '赝势', 'UPF']
    },
    {
        id: '03_k_sampling',
        number: 3,
        title: 'k空间采样与布里渊区',
        stars: '⭐',
        desc: '倒格子、Monkhorst-Pack网格、k点收敛测试',
        keywords: ['k点', '布里渊区', 'Monkhorst-Pack']
    },
    {
        id: '04_bands_and_dos',
        number: 4,
        title: '能带结构与态密度',
        stars: '⭐⭐',
        desc: 'NSCF计算、能带路径、DOS和投影态密度',
        keywords: ['能带', 'DOS', 'PDOS', '高对称点']
    },
    {
        id: '05_metallic_systems',
        number: 5,
        title: '金属体系与展宽方法',
        stars: '⭐⭐',
        desc: '金属vs绝缘体、展宽方法、Al和Cu计算',
        keywords: ['金属', '展宽', 'smearing', '费米面']
    },
    {
        id: '06_structural_optimization',
        number: 6,
        title: '结构优化与力学性质',
        stars: '⭐⭐⭐',
        desc: 'Hellmann-Feynman力、BFGS优化、变晶格优化',
        keywords: ['relax', 'vc-relax', 'BFGS', '应力']
    },
    {
        id: '07_magnetism',
        number: 7,
        title: '磁性与自旋极化计算',
        stars: '⭐⭐⭐',
        desc: '自旋极化DFT、铁磁/反铁磁、自旋轨道耦合',
        keywords: ['磁性', 'nspin', '自旋极化', 'SOC']
    },
    {
        id: '08_phonon_basics',
        number: 8,
        title: '声子计算与晶格动力学',
        stars: '⭐⭐⭐⭐',
        desc: 'DFPT、ph.x、声子色散、动力学矩阵',
        keywords: ['声子', 'DFPT', 'ph.x', '色散']
    },
    {
        id: '09_dielectric_spectroscopy',
        number: 9,
        title: '介电与光谱性质',
        stars: '⭐⭐⭐⭐',
        desc: '介电常数、Born有效电荷、IR/Raman光谱',
        keywords: ['介电', 'IR', 'Raman', 'Born电荷']
    },
    {
        id: '10_advanced_functionals',
        number: 10,
        title: '高级泛函与电子关联修正',
        stars: '⭐⭐⭐⭐',
        desc: 'DFT+U、范德华修正、杂化泛函HSE',
        keywords: ['DFT+U', 'vdW', 'HSE', 'Hubbard']
    },
    {
        id: '11_md_neb',
        number: 11,
        title: '分子动力学与反应路径',
        stars: '⭐⭐⭐⭐⭐',
        desc: 'BO-MD、CP-MD、NEB过渡态搜索',
        keywords: ['分子动力学', 'NEB', '过渡态', 'AIMD']
    },
    {
        id: '12_automation_capstone',
        number: 12,
        title: '综合实战与自动化',
        stars: '⭐⭐⭐⭐⭐',
        desc: '完整材料表征、Python自动化、高通量计算',
        keywords: ['Python', '自动化', '高通量', 'ASE']
    }
];

// ===== State =====
let currentChapter = null;
let completedChapters = new Set(JSON.parse(localStorage.getItem('qe_completed') || '[]'));
let isDark = localStorage.getItem('qe_theme') !== 'light';

// ===== Init =====
document.addEventListener('DOMContentLoaded', () => {
    initTheme();
    buildNav();
    buildOverview();
    updateProgress();
    initEventListeners();

    // Configure marked
    marked.setOptions({
        highlight: (code, lang) => {
            if (lang && hljs.getLanguage(lang)) {
                return hljs.highlight(code, { language: lang }).value;
            }
            return hljs.highlightAuto(code).value;
        },
        breaks: true,
        gfm: true
    });

    // Check URL hash for direct chapter link
    if (window.location.hash) {
        const chapterId = window.location.hash.slice(1);
        loadChapter(chapterId);
    }
});

// ===== Theme =====
function initTheme() {
    if (!isDark) {
        document.documentElement.setAttribute('data-theme', 'light');
        document.querySelector('.theme-icon').textContent = '☀️';
    }
}

function toggleTheme() {
    isDark = !isDark;
    if (isDark) {
        document.documentElement.removeAttribute('data-theme');
        document.querySelector('.theme-icon').textContent = '🌙';
        localStorage.setItem('qe_theme', 'dark');
    } else {
        document.documentElement.setAttribute('data-theme', 'light');
        document.querySelector('.theme-icon').textContent = '☀️';
        localStorage.setItem('qe_theme', 'light');
    }
}

// ===== Navigation =====
function buildNav() {
    const nav = document.getElementById('chapterNav');
    nav.innerHTML = CHAPTERS.map(ch => `
        <div class="nav-item ${completedChapters.has(ch.id) ? 'completed' : ''}" data-id="${ch.id}" onclick="loadChapter('${ch.id}')">
            <span class="nav-stars">${ch.stars}</span>
            <span class="nav-title">${ch.number}. ${ch.title}</span>
        </div>
    `).join('');
}

function buildOverview() {
    const overview = document.getElementById('chapterOverview');
    overview.innerHTML = CHAPTERS.map(ch => `
        <div class="chapter-card ${completedChapters.has(ch.id) ? 'completed' : ''}" onclick="loadChapter('${ch.id}')">
            <div class="card-number">第 ${ch.number} 章</div>
            <div class="card-title">${ch.title}</div>
            <div class="card-stars">${ch.stars}</div>
            <div class="card-desc">${ch.desc}</div>
        </div>
    `).join('');
}

// ===== Chapter Loading =====
async function loadChapter(chapterId) {
    const chapter = CHAPTERS.find(ch => ch.id === chapterId);
    if (!chapter) return;

    currentChapter = chapter;
    window.location.hash = chapterId;

    // Update nav active state
    document.querySelectorAll('.nav-item').forEach(item => {
        item.classList.toggle('active', item.dataset.id === chapterId);
    });

    // Show loading
    document.getElementById('welcomePage').style.display = 'none';
    document.getElementById('chapterContent').style.display = 'block';
    document.getElementById('markdownBody').innerHTML = '<div class="loading">加载中</div>';

    // Update header
    document.getElementById('chapterHeader').innerHTML = `
        <h1>第 ${chapter.number} 章：${chapter.title}</h1>
        <div class="chapter-meta">
            <span>难度：${chapter.stars}</span>
            <span>关键词：${chapter.keywords.join('、')}</span>
        </div>
    `;

    // Update navigation buttons
    document.getElementById('prevBtn').disabled = chapter.number <= 1;
    document.getElementById('nextBtn').disabled = chapter.number >= CHAPTERS.length;
    updateMarkButton();

    // Load markdown
    try {
        const response = await fetch(`site/${chapter.number.toString().padStart(2, '0')}.html`);
        if (!response.ok) throw new Error('File not found');
        const html = await response.text();
        document.getElementById('markdownBody').innerHTML = html;

        // Post-process: add copy buttons to code blocks
        addCopyButtons();

        // Render math with KaTeX
        renderMathInElement(document.getElementById('markdownBody'), {
            delimiters: [
                { left: '$$', right: '$$', display: true },
                { left: '$', right: '$', display: false },
                { left: '\\(', right: '\\)', display: false },
                { left: '\\[', right: '\\]', display: true }
            ],
            throwOnError: false,
            trust: true
        });

        // Scroll to top
        document.getElementById('mainContent').scrollTop = 0;
    } catch (e) {
        document.getElementById('markdownBody').innerHTML = `
            <div class="info-box">
                <strong>章节内容待生成</strong><br>
                此章节的详细内容正在准备中。您可以查看 <code>chapters/${chapter.id}/README.md</code> 获取原始 Markdown 文档。
            </div>
        `;
    }

    // Close mobile menu
    closeMobileMenu();
}

// ===== Code Copy Buttons =====
function addCopyButtons() {
    document.querySelectorAll('.markdown-body pre').forEach(pre => {
        const wrapper = document.createElement('div');
        wrapper.className = 'code-block-wrapper';
        pre.parentNode.insertBefore(wrapper, pre);
        wrapper.appendChild(pre);

        const btn = document.createElement('button');
        btn.className = 'copy-btn';
        btn.textContent = '复制';
        btn.onclick = () => {
            const code = pre.querySelector('code');
            navigator.clipboard.writeText(code ? code.textContent : pre.textContent);
            btn.textContent = '已复制!';
            setTimeout(() => btn.textContent = '复制', 2000);
        };
        wrapper.appendChild(btn);
    });
}

// ===== Progress =====
function updateProgress() {
    document.getElementById('progressCount').textContent = completedChapters.size;
    localStorage.setItem('qe_completed', JSON.stringify([...completedChapters]));

    // Update nav and overview
    document.querySelectorAll('.nav-item').forEach(item => {
        item.classList.toggle('completed', completedChapters.has(item.dataset.id));
    });
    document.querySelectorAll('.chapter-card').forEach((card, i) => {
        card.classList.toggle('completed', completedChapters.has(CHAPTERS[i].id));
    });
}

function updateMarkButton() {
    const btn = document.getElementById('markCompleteBtn');
    if (currentChapter && completedChapters.has(currentChapter.id)) {
        btn.textContent = '✓ 已完成';
        btn.classList.add('completed');
    } else {
        btn.textContent = '✓ 标记为已完成';
        btn.classList.remove('completed');
    }
}

function toggleComplete() {
    if (!currentChapter) return;
    if (completedChapters.has(currentChapter.id)) {
        completedChapters.delete(currentChapter.id);
    } else {
        completedChapters.add(currentChapter.id);
    }
    updateProgress();
    updateMarkButton();
}

// ===== Event Listeners =====
function initEventListeners() {
    document.getElementById('themeToggle').addEventListener('click', toggleTheme);

    document.getElementById('markCompleteBtn').addEventListener('click', toggleComplete);

    document.getElementById('prevBtn').addEventListener('click', () => {
        if (currentChapter && currentChapter.number > 1) {
            const prev = CHAPTERS.find(ch => ch.number === currentChapter.number - 1);
            if (prev) loadChapter(prev.id);
        }
    });

    document.getElementById('nextBtn').addEventListener('click', () => {
        if (currentChapter && currentChapter.number < CHAPTERS.length) {
            const next = CHAPTERS.find(ch => ch.number === currentChapter.number + 1);
            if (next) loadChapter(next.id);
        }
    });

    // Mobile menu
    document.getElementById('mobileMenuBtn').addEventListener('click', () => {
        document.getElementById('sidebar').classList.toggle('open');
        document.querySelector('.sidebar-overlay')?.classList.toggle('active');
    });

    // Create overlay
    const overlay = document.createElement('div');
    overlay.className = 'sidebar-overlay';
    overlay.addEventListener('click', closeMobileMenu);
    document.body.appendChild(overlay);

    // Keyboard navigation
    document.addEventListener('keydown', (e) => {
        if (e.key === 'ArrowLeft' && !document.getElementById('prevBtn').disabled) {
            document.getElementById('prevBtn').click();
        } else if (e.key === 'ArrowRight' && !document.getElementById('nextBtn').disabled) {
            document.getElementById('nextBtn').click();
        }
    });
}

function closeMobileMenu() {
    document.getElementById('sidebar').classList.remove('open');
    const overlay = document.querySelector('.sidebar-overlay');
    if (overlay) overlay.classList.remove('active');
}
