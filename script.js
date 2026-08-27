document.addEventListener('contextmenu', e => e.preventDefault());
document.addEventListener('dragstart', e => e.preventDefault());

const logo = document.getElementById('logoBox');
const titleBox = document.getElementById('titleBox');
const heroTitle = document.getElementById('heroTitle');

const storedLogo = localStorage.getItem('logoUrl');
if (storedLogo) {
  logo.innerHTML = `<img src="${storedLogo}" alt="logo">`;
}

const storedTitle = localStorage.getItem('titleUrl');
if (storedTitle) {
  titleBox.innerHTML = `<img src="${storedTitle}" alt="title">`;
  heroTitle.innerHTML = `<img src="${storedTitle}" alt="title">`;
}

function render(items) {
  const grid = document.getElementById('grid');
  grid.innerHTML = '';
  items.forEach(item => {
    const card = document.createElement('div');
    card.className = 'card';
    card.innerHTML = `
      <img src="${item.photo}" alt="${item.name}">
      <div class="card-body">
        <div class="card-title">${item.name}</div>
        <div class="card-desc">${item.desc}</div>
        <a href="${item.link}" target="_blank">СМОТРЕТЬ</a>
      </div>
    `;
    grid.appendChild(card);
  });
}

fetch('afisha.json')
  .then(r => r.json())
  .then(items => {
    render(items);
  })
  .catch(() => {
    document.getElementById('grid').innerHTML = '<p style="padding:24px; color:#ccc;">afisha.json не найден, бля</p>';
  });
