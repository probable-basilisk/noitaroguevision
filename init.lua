
function OnWorldPostUpdate() 
  if _rogue_vision_main then _rogue_vision_main() end
end

function OnPlayerSpawned( player_entity )
  dofile("data/roguevision/roguevision.lua")
end