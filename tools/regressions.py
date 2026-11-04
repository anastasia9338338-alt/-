"""Execute regression cases against functions extracted from the actual bundle."""
import re,subprocess

def check_regressions(modules,embedded,runner,folder):
    main=modules['Main']
    start=main.index('tbl12.DecoyGucci=requireModule')
    decoy=main[start:main.index('tbl12.GucciDestroy=requireModule',start)]
    can_spawn=re.search(r'CanSpawn=(function\(\).*?\n            end),',decoy,re.S)[1]
    spawn=re.search(r'SpawnToy=(function\(\).*?\n            end),',decoy,re.S)[1]
    train=re.search(r'SharedTrain=(function\(\).*?end),',decoy,re.S)[1]
    country=re.search(r'local flag12 = arg.Country == v24.*?return tostring\(arg.City\) < tostring\(arg2.City\)',main,re.S)[0]
    a=embedded.index('_G.sa2GetTgt = function()');z=embedded.index('\n\ndo\nlocal thread5 = nil',a)
    aim=embedded[a:z]
    a=embedded.index('local function fn41(arg, arg2, arg3)');z=embedded.index('local function fn42(arg, arg2, arg3)',a)
    ripple=embedded[a:z]
    a=embedded.index('at_startDummies = function()');z=embedded.index('at_stopDummies = function()',a)
    start_dummy=embedded[a:z]
    condition=re.search(r'if not \((not (?:_G\.)?_abanaRunning or n20 >= 10)\) then',embedded)[1]
    code='''local checks=0
local function check(v,m)assert(v,m);checks+=1 end
local V={};local mt={}
function V.new(x,y,z)return setmetatable({X=x,Y=y,Z=z or 0},mt)end
mt.__sub=function(a,b)return V.new(a.X-b.X,a.Y-b.Y,a.Z-b.Z)end
mt.__index=function(a,k)if k=='Magnitude'then return math.sqrt(a.X*a.X+a.Y*a.Y+a.Z*a.Z)end end
local Vector3,Vector2=V,V
local flags={InPlot={Value=false},InOwnedPlot={Value=false},CanSpawnToy={Value=true}}
local localPlayer={FindFirstChild=function(_,name)return flags[name]end}
local tbl7={States={},SpawnQueue={}}
local flag11=false;local v17={};local decoyModels={};local spawns=0
local tbl12={SpawnToy=function()spawns+=1;return{Parent=v17}end}
local expectedTrain={};local objects={FindFirstChild=function(_,n)if n=='Train'then return expectedTrain end end}
local map={FindFirstChild=function(_,n)if n=='AlwaysHereTweenedObjects'then return objects end end}
local workspace={FindFirstChild=function(_,n)if n=='Map'then return map end end}
'''
    code+='local GameFlags=(function()\n'+modules['GameFlags']+'\nend)()\n'
    code+='local function requireModule(name)assert(name=="GameFlags");return GameFlags end\n'
    code+='local canSpawn='+can_spawn+'\nlocal spawnToy='+spawn+'\nlocal sharedTrain='+train+'\n'
    code+='''check(canSpawn(),'Normal plot markers failed');check(spawnToy()~=nil and spawns==1,'Decoy spawn failed')
check(sharedTrain()==expectedTrain,'Shared train not resolved')
flags.InPlot.Value=true;check(not canSpawn()and spawnToy()==nil and spawns==1,'Foreign plot allowed a spawn')
flags.InOwnedPlot.Value=true;check(canSpawn(),'Own plot denied a spawn')
flags.InPlot=nil;check(not canSpawn()and spawnToy()==nil,'Missing marker was indexed')
flags.InPlot={Value=false};tbl7.States.Spawning=true;check(not canSpawn()and spawnToy()==nil,'Busy spawn bypassed')
tbl7.States.Spawning=false;flag11=true;check(not canSpawn()and spawnToy()==nil,'Unload allowed a spawn')
local v24='RU'
'''
    code+='local function countryFirst(arg,arg2)\n'+country+'\nend\n'
    code+='''check(countryFirst({Country='RU',City='Z'},{Country='US',City='A'}),'Preferred country was sorted after city')
check(not countryFirst({Country='US',City='A'},{Country='RU',City='Z'}),'Country ordering is not antisymmetric')
check(countryFirst({Country='RU',City='A'},{Country='RU',City='Z'}),'City tiebreak changed')
local _G={SA2={Enabled=true},_abanaRunning=true}
_G.sa2Pal=function()return false end;_G.sa2Wall=function()return false end
local function model(name,pos)return{FindFirstChild=function(_,key)if key==name then return{Position=pos}end end}end
local localPlayer2={};local enemy={};local Players={GetPlayers=function()return{localPlayer2,enemy}end}
local UserInputService={GetMouseLocation=function()return Vector2.new(0,0)end}
workspace.CurrentCamera={WorldToViewportPoint=function()return Vector3.new(0,0,0),true end}
local tbl46={Distance=100}
'''
    code+=aim+'\n'
    code+='''for _,own in ipairs({'HumanoidRootPart','saviHRP','realHrp'})do for _,target in ipairs({'HumanoidRootPart','saviHRP','realHrp'})do
localPlayer2.Character=model(own,Vector3.new(0,0,0));enemy.Character=model(target,Vector3.new(2,0,0))
check(_G.sa2GetTgt()==enemy,'Aim cannot resolve '..own..' / '..target)
end end
localPlayer2.Character=nil;check(_G.sa2GetTgt()==nil,'Aim did not tolerate respawn')
localPlayer2.Character=model('HumanoidRootPart',Vector3.new(0,0,0));_G.SA2.Enabled=false
check(_G.sa2GetTgt()==nil,'Disabled Aim remained active')
local n20=1
'''
    code+='check(not('+condition+'),"Shared running flag was read from the wrong table")\n'
    code+='''local created,deleted,tweens=0,0,{}
local bridge={TrackThread=function(_,v)return v end,TrackInstance=function(_,v)return v end,SetProperty=function(_,o,k,v)o[k]=v end}
local task={delay=function(_,fn)fn()end}
local Instance={new=function()created+=1;return{}end}
local UDim2={};local CFrame={new=function()return setmetatable({},{__mul=function()return{}end})end,Angles=function()return{}end}
local Enum={PartType={Cylinder=1},Material={SmoothPlastic=1},EasingStyle={Quad=1},EasingDirection={Out=1}}
local Color3={new=function()return{}end}
local tbl37={{Lerp=function()return{}end}}
local TweenInfo={new=function(seconds)return seconds end}
local TweenService3={Create=function(_,part,duration)tweens[part]=duration;return{Play=function()end}end}
local Debris={AddItem=function(_,part,duration)check(math.abs(duration-tweens[part]-.1)<1e-6,'Ripple expiry differs from its tween');deleted+=1 end}
'''
    code+=ripple+'\nfn41(Vector3.new(1,2,3),1,false)\n'
    code+='''check(created>0 and deleted==created,'Ripple cleanup swallowed an arithmetic error')
local refreshed,spawned=0,0
local fn45=function()refreshed+=1 end
local flag45=false;local tbl41={maxDummy=2};local at_spawnOneDummy=function()spawned+=1 end
'''
    code+=start_dummy+'\nat_startDummies()\n'
    code+='''check(refreshed==1 and spawned==2 and flag45,'Dummy start called an absent rainbow function')
print('PASS: '..checks..' source-derived regressions')
'''
    path=folder/'regressions.luau';path.write_text(code)
    result=subprocess.run([runner,str(path)],capture_output=True,text=True)
    assert result.returncode==0,(result.stdout,result.stderr)
    print(result.stdout.strip())
