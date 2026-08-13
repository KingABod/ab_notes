(() => {
  const app = document.getElementById('app');
  const notesList = document.getElementById('notesList');
  const notesCount = document.getElementById('notesCount');
  const titleInput = document.getElementById('titleInput');
  const contentInput = document.getElementById('contentInput');
  const charCount = document.getElementById('charCount');
  const statusMsg = document.getElementById('statusMsg');
  const saveBtn = document.getElementById('saveBtn');
  const deleteBtn = document.getElementById('deleteBtn');
  const closeBtn = document.getElementById('closeBtn');
  const newNoteBtn = document.getElementById('newNoteBtn');
  const confirmModal = document.getElementById('confirmModal');
  const confirmCancel = document.getElementById('confirmCancel');
  const confirmDelete = document.getElementById('confirmDelete');

  let notes = [];
  let selectedId = null; // null = new/unsaved note
  let limits = { maxTitle: 40, maxContent: 2000, maxNotes: 30 };
  let pendingDeleteId = null;

  const resourceName = (typeof GetParentResourceName === 'function') ? GetParentResourceName() : 'ab_note';

  function post(endpoint, data) {
    return fetch(`https://${resourceName}/${endpoint}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json; charset=UTF-8' },
      body: JSON.stringify(data || {})
    }).then(r => r.json()).catch(() => null);
  }

  function escapeHtml(str) {
    const div = document.createElement('div');
    div.innerText = str;
    return div.innerHTML;
  }

  function setStatus(text, type) {
    statusMsg.textContent = text || '';
    statusMsg.className = type || '';
    if (text) {
      setTimeout(() => {
        if (statusMsg.textContent === text) {
          statusMsg.textContent = '';
          statusMsg.className = '';
        }
      }, 2500);
    }
  }

  function renderList() {
    notesList.innerHTML = '';

    if (!notes.length) {
      notesList.innerHTML = '<div class="empty-state">No notes yet.<br>Click "+ New" to write one.</div>';
    } else {
      notes.forEach(note => {
        const item = document.createElement('div');
        item.className = 'note-item' + (note.id === selectedId ? ' active' : '');
        item.innerHTML = `
          <div class="note-title">${escapeHtml(note.title)}</div>
          <div class="note-updated">Updated: ${escapeHtml(note.updated_at || '')}</div>
          <div class="note-preview">${escapeHtml((note.content || '').slice(0, 60))}</div>
        `;
        item.addEventListener('click', () => selectNote(note.id));
        notesList.appendChild(item);
      });
    }

    const countLabel = limits.maxNotes && limits.maxNotes > 0
      ? `${notes.length} / ${limits.maxNotes} notes`
      : `${notes.length} note${notes.length === 1 ? '' : 's'}`;
    notesCount.textContent = countLabel;
  }

  function selectNote(id) {
    selectedId = id;
    const note = notes.find(n => n.id === id);
    titleInput.value = note ? note.title : '';
    contentInput.value = note ? note.content : '';
    deleteBtn.classList.toggle('hidden', !note);
    updateCharCount();
    renderList();
    setStatus('');
    titleInput.focus();
  }

  function newNote() {
    selectedId = null;
    titleInput.value = '';
    contentInput.value = '';
    deleteBtn.classList.add('hidden');
    updateCharCount();
    renderList();
    setStatus('');
    titleInput.focus();
  }

  function updateCharCount() {
    charCount.textContent = `${contentInput.value.length} / ${limits.maxContent}`;
  }

  function saveNote() {
    const title = titleInput.value.trim();
    const content = contentInput.value.trim();

    if (!title || !content) {
      setStatus('Title and content are required', 'error');
      return;
    }

    saveBtn.disabled = true;
    post('saveNote', { id: selectedId, title, content }).then(result => {
      saveBtn.disabled = false;
      if (!result) return;

      if (result.success) {
        setStatus(result.message || 'Saved', 'ok');

        if (selectedId === null && result.id) {
          selectedId = result.id;
        }

        const existing = notes.find(n => n.id === selectedId);
        if (existing) {
          existing.title = title;
          existing.content = content;
          existing.updated_at = 'just now';
        } else {
          notes.unshift({ id: selectedId, title, content, updated_at: 'just now' });
        }
        deleteBtn.classList.remove('hidden');
        renderList();
      } else {
        setStatus(result.message || 'Could not save note', 'error');
      }
    });
  }

  function askDelete() {
    if (selectedId === null) return;
    pendingDeleteId = selectedId;
    confirmModal.classList.remove('hidden');
  }

  function doDelete() {
    if (pendingDeleteId === null) return;
    const id = pendingDeleteId;
    confirmModal.classList.add('hidden');
    pendingDeleteId = null;

    post('deleteNote', { id }).then(result => {
      if (result && result.success) {
        notes = notes.filter(n => n.id !== id);
        if (selectedId === id) newNote();
        else renderList();
      } else {
        setStatus((result && result.message) || 'Could not delete note', 'error');
      }
    });
  }

  function closeNotebook() {
    post('close');
  }

  // ---------------- Events ----------------

  newNoteBtn.addEventListener('click', newNote);
  saveBtn.addEventListener('click', saveNote);
  deleteBtn.addEventListener('click', askDelete);
  closeBtn.addEventListener('click', closeNotebook);
  confirmCancel.addEventListener('click', () => {
    pendingDeleteId = null;
    confirmModal.classList.add('hidden');
  });
  confirmDelete.addEventListener('click', doDelete);

  contentInput.addEventListener('input', updateCharCount);

  document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') {
      if (!confirmModal.classList.contains('hidden')) {
        confirmModal.classList.add('hidden');
        pendingDeleteId = null;
      } else if (!app.classList.contains('hidden')) {
        closeNotebook();
      }
    } else if (e.ctrlKey && e.key === 's') {
      e.preventDefault();
      saveNote();
    }
  });

  window.addEventListener('message', (event) => {
    const data = event.data;
    if (!data || !data.action) return;

    if (data.action === 'open') {
      notes = data.notes || [];
      if (data.config) limits = data.config;
      app.classList.remove('hidden');
      newNote();
    } else if (data.action === 'refresh') {
      notes = data.notes || [];
      renderList();
    } else if (data.action === 'close') {
      app.classList.add('hidden');
      confirmModal.classList.add('hidden');
    }
  });
})();
