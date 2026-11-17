check(Store.Decode("aGVsbG8=")=="hello" and Store.Decode("eA==")=="x","Embedded image decoder lost padding or bytes")
local writes, removed, pending, callbacks={}, {}, {}, 0
local store=Store.Install({Write=function(path,data)writes[path]=data end,Register=function(path)return"asset://"..path end,
    Remove=function(path)removed[path]=true end,Name=function(serial)return"photo"..serial..".jpg"end,
    Spawn=function(fn)pending[#pending+1]=fn end})
check(store:Resolve(Catalog.Items[1].Source,function(asset)callbacks+=1;check(asset=="asset://photo1.jpg","Image did not use the registered local file")end),"Bundled background unexpectedly required an HTTP download")
pending[1]()
check(writes['photo1.jpg']=="hello" and callbacks==1,"Embedded image bytes did not reach the asset file")
check(not store:Resolve("https://example.com/custom.jpg",function()end),"Custom URL was mistaken for a bundled background")
store:Resolve(Catalog.Items[2].Source,function()callbacks+=1 end)
store:Dispose();pending[2]()
check(not writes['photo2.jpg'] and callbacks==1 and removed['photo1.jpg'],"Unload left image files or continued a delayed writer")
check(not store:Resolve(Catalog.Items[1].Source,function()end),"Closed background store accepted another job")
local waits=0
check(Store.Decode(string.rep("aGVs",20000),function()return waits==0 end,function()waits+=1 end)==nil,"Cancelled image decode continued after a yield")
print('PASS: '..checks..' embedded image decoding, custom URL fallback, delayed-load cancellation and local-file cleanup checks (mocked)')
