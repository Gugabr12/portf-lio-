// Dados compartilhados dos projetos (home + página "Todos os projetos").
// Os 3 primeiros são fixos; o resto vem do Supabase (posts publicados pelo admin.html).

const STATIC_PROJECTS = [
  {
    id: 'static-landing-ia',
    title: 'Landing Page IA Visual Masterclass',
    tags: ['Landing Page', 'Web Design'],
    image: 'https://mir-s3-cdn-cf.behance.net/project_modules/1400_webp/e8c5c9245637487.69b3f8deb9750.png',
    link: 'https://www.behance.net/gallery/245637487/Landing-Page-IA-Visual-Masterclass',
    external: true
  },
  {
    id: 'static-apple-store',
    title: 'Apple Store · iPhone 17',
    tags: ['Social Media', 'Design'],
    image: 'https://mir-s3-cdn-cf.behance.net/projects/max_808/0662a6235986815.Y3JvcCwzMTkwLDI0OTUsMzEsOTQ.png',
    link: 'https://www.behance.net/gallery/235986815/Social-Media-I-Apple-Store-I-iPhone-17',
    external: true
  },
  {
    id: 'static-carrossel',
    title: 'Social Media · Carrossel',
    tags: ['Carrossel', 'Instagram'],
    image: 'https://mir-s3-cdn-cf.behance.net/projects/max_808/df5570231282501.Y3JvcCw3NjksNjAxLDE5LDE1.png',
    link: 'https://www.behance.net/gallery/231282501/Social-Media-Carrossel',
    external: true
  }
];

// Busca os posts do Supabase (na ordem escolhida no admin) + os 3 fixos, já no formato comum.
async function getAllProjects() {
  let dynamic = [];
  try {
    if (window.supabase && typeof SUPABASE_URL !== 'undefined' && SUPABASE_URL.indexOf('COLE_AQUI') !== 0) {
      const sb = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
      const { data, error } = await sb
        .from('posts')
        .select('*')
        .order('sort_order', { ascending: true, nullsFirst: false })
        .order('created_at', { ascending: false });
      if (!error && data) {
        dynamic = data.map(function (p) {
          return {
            id: p.id,
            title: p.title,
            tags: p.tags && p.tags.length ? p.tags : ['Projeto'],
            image: p.image_url,
            link: '/' + encodeURIComponent(p.slug || p.id),
            external: false
          };
        });
      }
    }
  } catch (e) {
    // sem conexão com o Supabase ainda configurada — segue só com os fixos
  }
  return dynamic.concat(STATIC_PROJECTS);
}

function escapeHtmlCase(str) {
  const div = document.createElement('div');
  div.textContent = str || '';
  return div.innerHTML;
}

// Cria o elemento <a class="case-card"> de um projeto.
function renderCaseCard(project, featured) {
  const a = document.createElement('a');
  a.href = project.link;
  a.className = 'case-card' + (featured ? ' case-card--featured' : '');
  if (project.external) {
    a.target = '_blank';
    a.rel = 'noopener';
  }

  a.innerHTML =
    '<div class="case-card__media">' +
      '<img src="' + escapeHtmlCase(project.image) + '" alt="' + escapeHtmlCase(project.title) + '" loading="lazy">' +
    '</div>' +
    '<div class="case-card__meta">' +
      '<div class="case-card__info">' +
        '<div class="case-card__title">' + escapeHtmlCase(project.title) + '</div>' +
        '<div class="case-card__sub">' + escapeHtmlCase(project.tags[0] || '') + '</div>' +
      '</div>' +
      '<div class="case-card__link"><span class="case-card__link-icon">↗</span> Veja completo</div>' +
    '</div>';

  return a;
}
