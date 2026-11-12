local checks=0
local function check(value,message)assert(value,message);checks+=1 end
local notifications=0
local warn=function()end
local game={GetService=function()return{SetCore=function()notifications+=1 end}end}
local app={}
local function ready()
__GUARD__
return true
end
check(ready()==true,"An idle runtime cannot start")
local stops=0
app={Running=true,Starting=false,Library={Unload=function()stops+=1;app.Running=false end}}
check(ready()==true and stops==1,"An invisible existing session prevented replacement")
check(ready()==true and stops==1,"A stopped session was unloaded twice")
app={Running=true,Starting=true,Library={Unload=function()error("Must not race with initialization")end}}
check(ready()==nil and stops==1,"A simultaneous startup was torn down or duplicated")
app={Running=true,Library={Unload=function()error("Cleanup failed")end}}
check(ready()==nil and app.Running,"A new session started after failed cleanup")
app={Running=true}
check(ready()==nil,"A duplicate session started without a cleanup path")
check(notifications==3,"Blocked startup did not explain recovery")
print("PASS: "..checks.." existing-session replacement, concurrent startup and failed-cleanup checks (mocked)")
