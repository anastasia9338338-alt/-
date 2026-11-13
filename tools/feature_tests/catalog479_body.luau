local checks=0;local function check(v,m)assert(v,m);checks+=1 end
local data=newNode('Folder','DataModel');local world=newNode('Folder','Workspace');world.Parent=data
local storage=newNode('Folder','ReplicatedStorage');storage.Parent=data;local shop=newNode('Folder','ToyShop');shop.Parent=storage
local future=newNode('Model','ShopFutureItem');newNode('Part','Main').Parent=future;future.Parent=shop
local nested=newNode('Model','NestedPiece');newNode('Part').Parent=nested;nested.Parent=future
local button=newNode('ImageButton','Buy');button.Image='rbxassetid://fresh-thumbnail';button:SetAttribute('ToyName','ShopSpecialToy');button.Parent=shop
local other=newNode('Folder','Unrelated');other.Parent=storage;local unrelated=newNode('Model','NonShopModel');newNode('Part').Parent=unrelated;unrelated.Parent=other
local old=Catalog.Items.FoodBanana;Catalog.Discover({storage})
check(Catalog.Items.ShopFutureItem~=nil and Catalog.Items.ShopSpecialToy=='rbxassetid://fresh-thumbnail','Missing shop templates or attributed buy buttons')
check(Catalog.Items.NestedPiece==nil and Catalog.Items.NonShopModel==nil and Catalog.Items.Buy==nil,'Catalog invented component/UI item IDs')
check(Catalog.Items.FoodBanana==old,'Catalog overwrote existing thumbnail')
local alias=newNode('Model','RSCBanana');check(Catalog.ResolveId(alias)=='FoodBanana','Native banana alias unresolved')
local beat=signal();local esp=ObjectESP.Install({Workspace=world,Parent=world,Players={GetPlayerFromCharacter=function()end},
 RunService={Heartbeat=beat,RenderStepped=signal()},CatalogRoots={storage},Clock=function()return 10 end})
esp.Selected={FoodBanana=true};esp.ItemDropdown={SetValues=function(self,v)self.Values=v end,SetValueImages=function(self,v)self.Images=v end}
local late=newNode('Model','LateShopItem');newNode('Part').Parent=late;late.Parent=shop;esp:RefreshCatalog(true)
check(Catalog.Items.LateShopItem~=nil and table.find(esp.Items,'LateShopItem')and esp.Selected.FoodBanana,'Streamed catalog refresh lost IDs or selections')
check(table.find(esp.ItemDropdown.Values,'LateShopItem')and esp.ItemDropdown.Images.ShopSpecialToy=='rbxassetid://fresh-thumbnail','Visible item choices/images not refreshed')
local inv=newNode('Folder','OtherSpawnedInToys');inv.Parent=world;local live=newNode('Model','LiveOnlyToy');newNode('Part').Parent=live;live.Parent=inv
check(Catalog.Items.LiveOnlyToy~=nil and esp.Candidates[live]=='LiveOnlyToy','Live unknown shop toy omitted')
esp:RefreshCatalog(true);check(table.find(esp.Items,'LiveOnlyToy'),'Learned live toy not listed')
local connection=esp.CatalogWatched[storage];esp:Dispose();check(not connection.Connected,'Shop discovery observer leaked')
print('PASS: '..checks..' shop/templates, streamed and live Item ESP catalog checks (mocked)')
