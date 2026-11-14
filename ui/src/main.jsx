import React, { useEffect, useState } from 'react'
import { createRoot } from 'react-dom/client'
import './style.css'

const INITIAL = {
  name: '', label: '', category: 'general', dict: '', clip: '', flag: 49,
  step: 0.1, props: [],
}
const STEPS = [0.01, 0.1, 1.0, 10.0]
const VECTORS = [
  ['x', 'X'], ['y', 'Y'], ['z', 'Z'],
]

function nui(name, data = {}) {
  const resource = typeof GetParentResourceName === 'function' ? GetParentResourceName() : 'kora_emotemenu'
  return fetch(`https://${resource}/${name}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json; charset=UTF-8' },
    body: JSON.stringify(data),
  }).catch(() => {})
}

function setHighlight(color) {
  if (typeof color !== 'string' || !/^#[0-9a-f]{6}$/i.test(color)) return
  const root = document.documentElement.style
  const red = Number.parseInt(color.slice(1, 3), 16)
  const green = Number.parseInt(color.slice(3, 5), 16)
  const blue = Number.parseInt(color.slice(5, 7), 16)
  const channel = value => {
    const normalized = value / 255
    return normalized <= 0.03928 ? normalized / 12.92 : ((normalized + 0.055) / 1.055) ** 2.4
  }
  const luminance = 0.2126 * channel(red) + 0.7152 * channel(green) + 0.0722 * channel(blue)
  root.setProperty('--accent-color', color)
  root.setProperty('--accent-soft', `rgb(${red} ${green} ${blue} / 14%)`)
  root.setProperty('--accent-border', `rgb(${red} ${green} ${blue} / 45%)`)
  root.setProperty('--accent-foreground', luminance > 0.42 ? '#101010' : '#ffffff')
}

function App() {
  const [visible, setVisible] = useState(false)
  const [editor, setEditor] = useState(INITIAL)
  const [categories, setCategories] = useState(['general', 'dance', 'props'])
  const [categoryLabels, setCategoryLabels] = useState({})
  const [strings, setStrings] = useState({})
  const [maxLabel, setMaxLabel] = useState(0)
  const [playing, setPlaying] = useState(false)
  const [savedEmotes, setSavedEmotes] = useState([])
  const [savedLoaded, setSavedLoaded] = useState(false)
  const [showSaved, setShowSaved] = useState(false)
  const [savedSearch, setSavedSearch] = useState('')
  const [pendingDelete, setPendingDelete] = useState(null)

  useEffect(() => {
    const receive = (event) => {
      const message = event.data || {}
      if (message.action === 'open') {
        setHighlight(message.primary)
        setShowSaved(false)
        setEditor({ ...INITIAL, ...(message.editor || {}), props: message.editor?.props || [] })
        setCategories(message.categories || ['general', 'dance', 'props'])
        setCategoryLabels(message.categoryLabels || {})
        setStrings(message.strings || {})
        setMaxLabel(Number(message.maxLabelLength) || 0)
        setPlaying(Boolean(message.playing))
        setVisible(true)
      } else if (message.action === 'state') {
        if (message.strings) setStrings(message.strings)
        if (message.categoryLabels) setCategoryLabels(message.categoryLabels)
        setEditor((current) => ({ ...current, ...(message.editor || {}), props: message.editor?.props || current.props }))
        if (message.playing !== undefined) setPlaying(Boolean(message.playing))
      } else if (message.action === 'savedEmotes') {
        setSavedEmotes(message.emotes || [])
        setSavedLoaded(true)
      } else if (message.action === 'loaded') {
        setEditor({ ...INITIAL, ...(message.editor || {}), props: message.editor?.props || [] })
        setShowSaved(false)
        setSavedSearch('')
      } else if (message.action === 'resetDeletedEditor') {
        setEditor({ ...INITIAL, ...(message.editor || {}), props: [] })
      } else if (message.action === 'theme') {
        setHighlight(message.primary)
      } else if (message.action === 'kora_theme:override') {
        const primary = typeof message.data === 'string' ? message.data : message.data?.primary
        setHighlight(primary)
      } else if (message.action === 'hide' || message.action === 'close') {
        setVisible(false)
        if (message.action === 'close') setEditor(INITIAL)
      }
    }
    window.addEventListener('message', receive)
    const keys = (event) => {
      if (event.key === 'Escape' && visible) {
        event.preventDefault()
        setShowSaved(false)
        setVisible(false)
        nui('creator:close')
      }
    }
    window.addEventListener('keydown', keys)
    return () => {
      window.removeEventListener('message', receive)
      window.removeEventListener('keydown', keys)
    }
  }, [visible])

  const update = (patch) => {
    setEditor((current) => {
      const next = { ...current, ...patch }
      nui('creator:change', next)
      return next
    })
  }
  const updateProp = (index, patch) => {
    const props = editor.props.map((prop, i) => i === index ? { ...prop, ...patch } : prop)
    update({ props })
  }
  const updateVector = (index, group, axis, value) => {
    const prop = editor.props[index]
    const vector = { ...(prop[group] || { x: 0, y: 0, z: 0 }), [axis]: value }
    updateProp(index, { [group]: vector })
  }
  const changeBy = (index, group, axis, direction) => {
    const current = Number(editor.props[index]?.[group]?.[axis]) || 0
    const next = Number((current + editor.step * direction).toFixed(4))
    updateVector(index, group, axis, next)
  }
  const act = (action, index) => nui('creator:action', { action, index: index == null ? undefined : index + 1 })
  const openSaved = () => {
    setSavedEmotes([])
    setSavedLoaded(false)
    setSavedSearch('')
    setPendingDelete(null)
    setShowSaved(true)
    nui('creator:action', { action: 'load-list' })
  }
  const loadSaved = name => nui('creator:action', { action: 'load', name })
  const close = () => {
    setShowSaved(false)
    setVisible(false)
    nui('creator:close')
  }
  const t = (key, ...values) => {
    let value = strings[key] || key
    values.forEach(item => { value = value.replace('%s', item).replace('%d', item) })
    return value
  }

  if (!visible) return null

  return <main className="veil">
    <section className="window">
      <header className="topbar">
        <div className="brand"><div className="mark">K</div><div><div className="eyebrow">{t('eyebrow')}</div><h1>{editor.editingName ? t('editing', editor.label || editor.name) : t('title')}</h1></div></div>
        <div className="header-actions"><button className="button quiet" onClick={() => editor.editingName ? act('new') : openSaved()}>{editor.editingName ? t('new_emote') : t('edit_saved')}</button><button className="icon-button" onClick={close} aria-label={t('close')}>×</button></div>
      </header>
      <div className="toolbar">
        <div className="status"><span className={`dot ${playing ? 'active' : ''}`} />{playing ? t('preview_playing') : t('preview_ready')}</div>
        <div className="toolbar-actions">
          <button className="button quiet" onClick={() => act('freecam')}>{t('freecam')}</button>
          <button className={`button ${playing ? 'quiet' : 'primary'}`} onClick={() => act(playing ? 'stop' : 'play')}>{playing ? t('stop_preview') : t('play_preview')}</button>
        </div>
      </div>
      <div className="content">
        <section className="card">
          <div className="section-heading"><div><div className="eyebrow">{t('animation_eyebrow')}</div><h2>{t('animation_details')}</h2></div></div>
          <div className="field-grid">
            <label className="field"><span>{t('emote_name')}</span><input value={editor.name} onChange={e => update({ name: e.target.value })} placeholder={t('emote_name_example')} /></label>
            <label className="field"><span>{t('display_label')}</span><input value={editor.label} maxLength={maxLabel || undefined} onChange={e => update({ label: e.target.value })} placeholder={t('display_label_example')} />{maxLabel > 0 && <small>{(editor.label || "").length}/{maxLabel} {t('characters')}</small>}</label>
            <label className="field"><span>{t('animation_dictionary')}</span><input value={editor.dict} onChange={e => update({ dict: e.target.value })} placeholder="anim@amb@clubhouse@bar@drink@" /></label>
            <label className="field"><span>{t('animation_clip')}</span><input value={editor.clip} onChange={e => update({ clip: e.target.value })} placeholder="idle_a" /></label>
            <label className="field"><span>{t('category')}</span><select value={editor.category} onChange={e => update({ category: e.target.value })}>{categories.map(category => <option key={category} value={category}>{categoryLabels[category] || category}</option>)}</select></label>
            <label className="field small-field"><span>{t('animation_flag')}</span><input type="number" step="1" value={editor.flag ?? 49} onChange={e => update({ flag: Number(e.target.value) })} /></label>
          </div>
        </section>

        <section className="card props-card">
          <div className="section-heading prop-heading"><div><div className="eyebrow">{t('attachments_eyebrow')}</div><h2>{t('props')} <span className="count">{editor.props.length}/2</span></h2></div>
            {editor.props.length < 2 && <button className="button quiet" onClick={() => act('add')}>{t('add_prop')}</button>}
          </div>
          {!editor.props.length && <div className="empty"><span className="empty-icon">＋</span><div><strong>{t('no_props')}</strong><p>{t('add_object')}</p></div></div>}
          {editor.props.map((prop, index) => <article className="prop" key={index}>
            <div className="prop-top"><div className="prop-title"><span className="prop-index">0{index + 1}</span><div><strong>{t('prop', index + 1)}</strong><small>{prop.modelName || t('model_name_hint')}</small></div></div><button className="remove" onClick={() => act('remove', index)}>{t('remove')}</button></div>
            <div className="prop-fields">
              <label className="field model-field"><span>{t('object_model')}</span><input value={prop.modelName || ''} onChange={e => updateProp(index, { modelName: e.target.value })} placeholder="prop_cs_ciggy_01" /><small>{t('object_model_hint')}</small></label>
              <label className="field bone-field"><span>{t('ped_bone_id')}</span><input type="number" step="1" value={prop.bone ?? 0} onChange={e => updateProp(index, { bone: Number(e.target.value) })} /><small>{t('bone_example')}</small></label>
            </div>
            <div className="step-row"><div><strong>{t('adjustment_amount')}</strong><small>{t('adjustment_hint')}</small></div><div className="step-buttons">{STEPS.map(step => <button key={step} className={editor.step === step ? 'selected' : ''} onClick={() => update({ step })}>{step.toFixed(step === 0.01 ? 2 : 1)}</button>)}</div></div>
            <VectorGroup title={t('offset')} subtitle={t('position_relative')} group="offset" prop={prop} index={index} step={editor.step} onChange={updateVector} onNudge={changeBy} strings={strings} />
            <VectorGroup title={t('rotation')} subtitle={t('angle_axes')} group="rotation" prop={prop} index={index} step={editor.step} onChange={updateVector} onNudge={changeBy} strings={strings} />
            <div className="prop-footer"><span>{t('preview_changes')}</span><button className="button apply" onClick={() => act('apply', index)}>{t('apply_model')}</button></div>
          </article>)}
        </section>
      </div>
      <footer className="footer"><span>{t('close_preview_hint')}</span><button className="button primary save" onClick={() => act('save')}>{editor.editingName ? t('save_changes') : t('save_emote')} <span>→</span></button></footer>
    </section>
    {showSaved && <div className="picker-backdrop" onMouseDown={event => { if (event.target === event.currentTarget) setShowSaved(false) }}>
      <section className="picker">
        <header className="picker-head"><div><div className="eyebrow">{t('saved_emotes')}</div><h2>{t('edit_emote')}</h2></div><button className="icon-button" onClick={() => setShowSaved(false)} aria-label={t('close')}>×</button></header>
        <input className="picker-search" autoFocus value={savedSearch} onChange={event => setSavedSearch(event.target.value)} placeholder={t('search_saved')} />
        <div className="saved-list">
          {savedEmotes.filter(emote => `${emote.name} ${emote.label}`.toLowerCase().includes(savedSearch.toLowerCase())).map(emote => <div className="saved-row" key={emote.name}><button className="saved-item" onClick={() => loadSaved(emote.name)}><span className="saved-icon">✎</span><span className="saved-description"><strong>{emote.label}</strong><small>{emote.name} · {categoryLabels[emote.category] || emote.category}</small></span><span className="saved-arrow">→</span></button><button className="saved-delete" onClick={() => setPendingDelete(emote)} aria-label={`${t('delete')} ${emote.label}`}>{t('delete')}</button></div>)}
          {!savedLoaded && <p className="picker-empty">{t('loading_saved')}</p>}
          {savedLoaded && !savedEmotes.length && <p className="picker-empty">{t('no_saved')}</p>}
          {savedEmotes.length > 0 && !savedEmotes.some(emote => `${emote.name} ${emote.label}`.toLowerCase().includes(savedSearch.toLowerCase())) && <p className="picker-empty">{t('no_search_match')}</p>}
        </div>
        {pendingDelete && <div className="delete-confirm"><div className="delete-dialog"><div className="eyebrow">{t('remove_saved')}</div><h3>{t('delete_confirm', pendingDelete.label)}</h3><p>{t('delete_description')}</p><div className="delete-actions"><button className="button quiet" onClick={() => setPendingDelete(null)}>{t('cancel')}</button><button className="button danger" onClick={() => { nui('creator:action', { action: 'delete', name: pendingDelete.name }); setPendingDelete(null) }}>{t('delete_emote')}</button></div></div></div>}
      </section>
    </div>}
  </main>
}

function VectorGroup({ title, subtitle, group, prop, index, step, onChange, onNudge, strings }) {
  const t = (key, ...values) => {
    let value = strings[key] || key
    values.forEach(item => { value = value.replace('%s', item).replace('%d', item) })
    return value
  }
  return <div className="vector-group"><div className="vector-title"><strong>{title}</strong><small>{subtitle}</small></div><div className="axis-grid">{VECTORS.map(([axis, label]) => <div className="axis" key={axis}><span>{label}</span><button onClick={() => onNudge(index, group, axis, -1)} aria-label={t('decrease', title, label)}>−</button><input type="number" step={step} value={prop[group]?.[axis] ?? 0} onChange={e => onChange(index, group, axis, e.target.value === '' ? 0 : Number(e.target.value))} /><button onClick={() => onNudge(index, group, axis, 1)} aria-label={t('increase', title, label)}>＋</button></div>)}</div></div>
}

createRoot(document.getElementById('root')).render(<App />)
