---
name: chrome-ui-testing
description: Load before test-driving any web UI for the user (a production or staging app, a dashboard, a PR preview) - "test drive the UI", "check it works in the browser", "does it fit on a phone", "exercise every feature". Covers driving the user's real Chrome through Claude in Chrome (not the built-in browser pane), keeping their sign-in, measuring phone viewports below Chrome's minimum window width with a same-origin iframe, reading the app's API with the page's own cookie, finding hover-only controls, and logging findings to a ledger as you go.
---

# Test-driving a web UI in Chrome

Owner, 2026-10-18 (a private project's UI test drive): "use claude-in-chrome to get around the
permissions limitations". The built-in browser pane asks the user to approve actions one by one;
their Chrome does not. Load the `anthropic-skills:chrome-browser` skill for the tool mechanics;
this page is the testing method.

## 1. Rules

- **Drive the user's real Chrome** (`mcp__claude-in-chrome__*`). Load the core tools plus
  `javascript_tool`, `find`, `get_page_text`, `form_input`, `browser_batch`, `resize_window`
  in ONE ToolSearch call. Work in a new tab (`tabs_create_mcp`); close your tabs at the end.
- **The user's sign-in is theirs.** The site cookie usually carries their session. Never click Log out
  unless sign-out is the thing under test, and then do it LAST and say so first: logging out
  revokes the server session and they have to sign in again (this cost a round trip on
  2026-10-18). If a page shows sign-in, ask them to sign in in that tab; a password-manager
  autofill path may fail when its helper app is unreachable.
- **Batch.** `browser_batch` for click → wait → read sequences; read with `get_page_text` or
  `find`, screenshot only when the layout is the point.
- **Log every finding as you go** in a ledger file in the working tree (area, what happened,
  severity, status) so fixes can be batched; list what you could not test as NOT RUN.
- **Confirm before the irreversible.** Purge, delete, sending messages to other people: only
  on test data you created, never on theirs.

## 2. Reading the app's API from the page

`javascript_tool` runs in the page, so `fetch('/api/...', {credentials:'include'})` uses their
cookie: the fastest way to read a record's true state next to what the UI shows. Compare the
two: a UI that lags the API is a live-update bug; a UI that matches a stale API is a server
bug. Return compact JSON (`JSON.stringify` of picked fields), never whole payloads.

## 3. Phone sizes

Chrome's window will not go below ~606 px wide, so `resize_window` cannot reach a phone.
Load the app in fixed-size same-origin iframes instead; the app's media queries follow the
iframe size. Measure inside each frame:

```js
const sizes=[['small phone',360,780],['large phone',430,932],['tablet',768,1024]];
document.body.innerHTML=''; const out={};
for (const [name,w,h] of sizes) for (const p of ['/','/some/detail/route']) {
  const f=document.createElement('iframe'); f.style.cssText=`width:${w}px;height:${h}px;border:0`;
  f.src=p; document.body.appendChild(f); await new Promise(r=>f.onload=r); await new Promise(r=>setTimeout(r,3000));
  const win=f.contentWindow, de=win.document.documentElement; win.scrollTo(0,99999); const sy=win.scrollY; win.scrollTo(99999,0); const sx=win.scrollX; win.scrollTo(0,0);
  out[name+' '+p]={docH:de.scrollHeight,H:win.innerHeight,docW:de.scrollWidth,W:win.innerWidth,windowScrollY:sy,windowScrollX:sx};
  f.remove();
}
JSON.stringify(out)
```

A full-screen app passes when `windowScrollY` and `windowScrollX` are 0 and `docH == H`:
only inner regions scroll. Check the main input stays inside the frame. Navigate the tab back
to the app afterwards (the script replaces the page). Use the sizes of the devices the
project targets; the list above is an example. Real iOS Safari (dynamic toolbars, `dvh`) is NOT
covered by this; say so.

## 4. Controls you cannot see

Row menus that appear on hover have no visible target. Find the element, convert its
CSS-pixel centre to the screenshot frame, and click there:

```js
const b=document.querySelector('[aria-label="Row actions for …"]'); const r=b.getBoundingClientRect();
const k=SCREENSHOT_FRAME_WIDTH/innerWidth; ({x:Math.round((r.x+r.width/2)*k), y:Math.round((r.y+r.height/2)*k)})
```

A control a person cannot reach by keyboard or touch is itself a finding.

## 5. What to exercise

Sign-in and session restore; every list and its states; create; each detail panel; every
row and header menu action; approvals both ways; live updates (compare with the API after
each action, and once after a reload); the slow path (a cold start, a resume after long
idle); phone sizes; sign-out last.
