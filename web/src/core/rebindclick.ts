addEventListener("click", (e) => {
  const el = e.target instanceof Element ? e.target.closest("[data-rebind]") : null
  const id = el?.getAttribute("data-rebind")
  if (!el || !id) return
  e.preventDefault()
  e.stopPropagation()
  void import("@/core/rebind").then((m) => m.rebind(id, el, el.getAttribute("data-rebind-keys") ?? undefined))
}, true)
