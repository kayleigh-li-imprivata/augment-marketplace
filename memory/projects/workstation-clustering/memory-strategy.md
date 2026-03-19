# Memory Strategy - TOC Approach

## 🎯 Token Efficiency

### ❌ Auto-Loading (Old Approach)
```
index.md with [[wiki-links]]
→ Augment auto-loads ALL linked files
→ ~1,334 lines = 10-15K tokens EVERY session
```

### ✅ Table of Contents (Current Approach)
```
index.md = lightweight TOC (NO wiki-links)
→ Augment loads index only (~67 lines)
→ Loads specific files on-demand based on conversation
→ Saves 80-90% tokens when discussing single topic
```

---

## 📊 Token Savings

| Scenario | Auto-Load | TOC | Savings |
|----------|-----------|-----|---------|
| Discussing releases only | ~15K | ~2K | **87%** ✅ |
| Discussing sandbox testing | ~15K | ~3K | **80%** ✅ |
| Discussing all topics | ~15K | ~15K | 0% |

---

## 📝 How to Add New Knowledge

### Quick Command
> "Add what we discussed about [topic] to memory as [filename].md"

### What Happens
1. Create `~/.augment/memory/workstation-clustering/[filename].md`
2. Update `index.md` with entry and description
3. Keep content concise (summary, not full transcript)

### File Naming
- Use lowercase with hyphens: `race-conditions.md`
- Be descriptive: `otel-integration.md` not `otel.md`
- Group related topics in subdirectories if needed

---

## 🔑 Key Principle

**Index = Lightweight TOC**
- Brief descriptions of what's available
- File names and line counts
- NO wiki-links (prevents auto-loading)
- Augment loads files on-demand using `view` tool
