
 return KeyPicker,UserInputService,function()return InputChanged end
end
local a,ai,ac=makePicker('A');local b,bi,bc=makePicker('B')
local first={UserInputType='Keyboard',KeyCode={Name='A'},Changed=signal()}
local second={UserInputType='Keyboard',KeyCode={Name='B'},Changed=signal()}
ai.InputBegan:Fire(first);bi.InputBegan:Fire(second)
local ca,cb=ac(),bc();check(ca and cb and ca~=cb,'Held keys shared an observer')
a.Pressed=false;first.Changed:Fire()
check(not ca.Connected and cb.Connected and ac()==nil,'Releasing one key disconnected the other key')
b.Pressed=false;second.Changed:Fire()
check(not cb.Connected and bc()==nil,'Second release leaked its observer')
a.Pressed=true;ai.InputBegan:Fire(first);local previous=ac();ai.InputBegan:Fire(first)
check(not previous.Connected and ac().Connected,'Repeated keydown leaked the old observer')
local held=ac();Library.Unloaded=true;for _,fn in ipairs(Library.UnloadCallbacks)do fn()end
check(not held.Connected and ac()==nil,'Unload leaked a held observer when parent skipped addon destruction')
print('PASS: '..checks..' concurrent hold-key observer regressions')
