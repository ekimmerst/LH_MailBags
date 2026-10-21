from pathlib import Path
import sys

addon = Path(__file__).resolve().parent
core = addon.parent / 'LH_Tweaks'
sys.path.insert(0, str(core / '.test-runtime'))
from lupa.lua51 import LuaRuntime

for mode in ('Blizzard', 'Baganator'):
    lua = LuaRuntime()
    lua.globals().MODE = mode
    lua.execute('''
frames={};SlashCmdList={};timers={};messages={};bags={};opens=0;closes=0
NUM_TOTAL_BAG_FRAMES=4
function print(message) table.insert(messages,message) end
function CreateFrame()
 local f={scripts={},hooks={},shown=false}
 function f:RegisterEvent() end
 function f:SetScript(k,v) self.scripts[k]=v end
 function f:HookScript(k,v) self.hooks[k]=self.hooks[k] or {};table.insert(self.hooks[k],v) end
 function f:IsShown() return self.shown end
 function f:Show()
  if self.shown then return end;self.shown=true
  for _,fn in ipairs(self.hooks.OnShow or {}) do fn(self) end
 end
 function f:Hide()
  if not self.shown then return end;self.shown=false
  for _,fn in ipairs(self.hooks.OnHide or {}) do fn(self) end
 end
 frames[#frames+1]=f;return f
end
C_Timer={After=function(_,fn) table.insert(timers,fn) end}
function drain() local pending=timers;timers={};for _,fn in ipairs(pending) do fn() end end
function OpenBag(id) bags[id]=true;opens=opens+1 end
function CloseAllBags() bags={};closes=closes+1 end
if MODE=='Baganator' then
 Baganator={CallbackRegistry={TriggerEvent=function(_,event)
  if event=='BagShow' then baganatorOpen=true;opens=opens+1
  elseif event=='BagHide' then baganatorOpen=false;closes=closes+1
  else error(event) end
 end}}
end
function bagOpen() return MODE=='Baganator' and baganatorOpen or bags[0] end
registry={};notices={};buttons={};Settings={}
function Settings.RegisterVerticalLayoutSubcategory(parent,title)
 local c={parent=parent,title=title};function c:GetID() return self.title end
 local l={rows={}};function l:AddInitializer(row) table.insert(self.rows,row) end;c.layout=l;return c,l
end
function Settings.RegisterAddOnCategory(c) registered=c end
function Settings.RegisterProxySetting(c,v,kind,label,default,get,set)
 local s={default=default,get=get,set=set};registry[v]=s;return s
end
function Settings.CreateCheckbox(c,s,t)
 local row={setting=s,tooltip=t}
 function row:SetParentInitializer(parent,predicate) self.parent=parent;self.canModify=predicate end
 c.layout:AddInitializer(row);return row
end
function Settings.NotifyUpdate(v) notices[v]=(notices[v] or 0)+1 end
function Settings.OpenToCategory(id) opened=id end
function CreateSettingsListSectionHeaderInitializer(title) return {header=title} end
function CreateSettingsButtonInitializer(label,text,fn) buttons[text]=fn;return {label=label} end
LH_Tweaks={modules={}}
LH_MailBagsDB={closeOnHide=false}
''')
    source = (core / 'LH_Tweaks.lua').read_text()
    registration = source.split('function Hub:RegisterModule(id, title, build)')[1].split('\nfunction Hub:RestoreDefaults')[0]
    lua.execute('local Hub=LH_Tweaks\nfunction Hub:RegisterModule(id, title, build)' + registration)
    source = (core / 'Settings.lua').read_text()
    registration = source.split('function Hub:RegisterModulePage(id)')[1].split('\nlocal function RegisterSettings')[0]
    lua.execute('local Hub=LH_Tweaks\nfunction Hub:RegisterModulePage(id)' + registration)
    lua.execute((addon / 'LH_MailBags.lua').read_text(), 'LH_MailBags')
    lua.execute((addon / 'Settings.lua').read_text(), 'LH_MailBags')
    lua.execute('''
local events=frames[1]
local function fire(event,name) events.scripts.OnEvent(events,event,name) end
assert(not registered and LH_Tweaks.modules.LH_MailBags)
fire('ADDON_LOADED','LH_MailBags')
assert(LH_MailBagsDB.enabled and not LH_MailBagsDB.closeOnHide,'Saved close preference lost')
LH_Tweaks.category={};LH_Tweaks:RegisterModulePage('LH_MailBags')
assert(registered.parent==LH_Tweaks.category and registered.title=='LH MailBags')
assert(#registered.layout.rows==3 and next(buttons)==nil,'Diagnostic control still present')
local enable,close=registry.LH_MailBags_enabled,registry.LH_MailBags_closeOnHide
assert(enable.default and close.default and enable.get() and not close.get())
local dependent=registered.layout.rows[3]
assert(dependent.parent==registered.layout.rows[2] and dependent.canModify())
SlashCmdList.LH_MAILBAGS();assert(opened=='LH MailBags')
-- Mail UI loading after login and repeated loading events install only one hook.
fire('PLAYER_LOGIN');MailFrame=CreateFrame()
fire('ADDON_LOADED','Blizzard_MailFrame');fire('ADDON_LOADED','Other')
assert(#MailFrame.hooks.OnShow==1 and #MailFrame.hooks.OnHide==1)
MailFrame:Show();assert(opens==0);drain();assert(bagOpen())
local shown=opens;MailFrame:Hide();drain();assert(bagOpen() and opens>shown,'Keep-open preference ignored')
SlashCmdList.LH_MAILBAGS('close on');assert(close.get() and notices.LH_MailBags_closeOnHide>0)
MailFrame:Show();drain();MailFrame:Hide();drain();assert(not bagOpen() and closes==1)
-- Disable after a mailbox show but before its queued action can execute.
MailFrame:Show();local previousOpens=opens;enable.set(false);drain()
assert(opens==previousOpens and not bagOpen() and not dependent.canModify())
MailFrame:Hide();drain();assert(closes==1)
MailFrame:Show();drain();assert(opens==previousOpens,'Disabled mailbox still opens bags')
-- Enabling with the mailbox visible opens bags; disabling leaves them alone.
SlashCmdList.LH_MAILBAGS(' ON ');drain();assert(bagOpen() and enable.get())
enable.set(false);MailFrame:Hide();drain();assert(bagOpen() and closes==1)
assert(close.get(),'Disabling destroyed the saved close preference')
-- A pending close is canceled by disabling, too.
enable.set(true);MailFrame:Show();drain();MailFrame:Hide();enable.set(false);drain()
assert(bagOpen() and closes==1,'Pending close survived disabling')
-- Native defaults restore both proxies and preserve other module settings.
LH_JobsDoneDB={enabled=false};enable.set(enable.default);close.set(close.default)
assert(enable.get() and close.get() and not LH_JobsDoneDB.enabled)
MailFrame:Show();MailFrame:Hide();MailFrame:Show();previousOpens=opens;drain()
assert(bagOpen() and opens==previousOpens+(MODE=='Blizzard' and 5 or 1),'Stale rapid-transition actions executed')
MailFrame:Hide();drain();assert(not bagOpen())
close.set(false);MailFrame:Show();drain()
-- Simulate Blizzard closing bags synchronously; our deferred keep-open restores them.
MailFrame:Hide();bags={};baganatorOpen=false;drain();assert(bagOpen())
SlashCmdList.LH_MAILBAGS('status');assert(not messages[#messages]:find('Client') and not messages[#messages]:find('API:'))
local state=enable.get();SlashCmdList.LH_MAILBAGS('off extra');assert(enable.get()==state)
enable.set(false);close.set(false);fire('PLAYER_LOGIN')
assert(not enable.get() and not close.get(),'Saved disabled state lost at login')
-- Missing integration APIs warn once, and disabled mode remains quiet.
local oldBaganator,oldOpen=Baganator,OpenBag
if MODE=='Baganator' then Baganator={CallbackRegistry={}} else OpenBag=nil end
local count=#messages;MailFrame:Show();MailFrame:Hide();assert(#messages==count)
enable.set(true);MailFrame:Show();MailFrame:Hide();MailFrame:Show();drain()
assert(#messages==count+1,'Missing API warning was repeated')
Baganator,OpenBag=oldBaganator,oldOpen
''')
    print(f'PASS: {mode}, real host registration, both settings/defaults, saved preferences, deferred actions, cancellation, rapid transitions, late loading, removed diagnostics and missing APIs')

for ext in ('png', 'tga'):
    assert (addon / f'Media/Icon.{ext}').read_bytes() == (core / f'Icon.{ext}').read_bytes()
toc = (addon / 'LH_MailBags.toc').read_text()
assert '## Group: LH_Tweaks' in toc and 'Settings.lua' in toc
print('PASS: shared icon files and integration metadata')
