document.addEventListener('contextmenu', e => e.preventDefault());
document.addEventListener('dragstart', e => e.preventDefault());

const logo = document.getElementById('logoBox');
const titleBox = document.getElementById('titleBox');

const storedLogo = localStorage.getItem('logoUrl');
if (storedLogo) {
  logo.innerHTML = `<img src="https://i.postimg.cc/28msyBss/In-Shot-20260827-123502358.png" alt="logo">`;
}

const storedTitle = localStorage.getItem('titleUrl');
if (storedTitle) {
  titleBox.innerHTML = `<img src="${storedTitle}" alt="title">`;
}

function render(items) {
  const grid = document.getElementById('grid');
  grid.innerHTML = '';
  items.forEach(item => {
    const card = document.createElement('div');
    card.className = 'card';

    const img = document.createElement('img');
    img.src = item.photo;
    img.alt = item.name;
    img.addEventListener('click', () => {
      window.open(item.link, '_blank');
    });

    const body = document.createElement('div');
    body.className = 'card-body';

    const title = document.createElement('div');
    title.className = 'card-title';
    title.textContent = item.name;

    body.appendChild(title);
    card.appendChild(img);
    card.appendChild(body);
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
