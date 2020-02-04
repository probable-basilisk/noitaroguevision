-- -- try to use better ws coroutines first
-- dofile_once("data/ws/coroutines.lua")
-- if not async then
--   dofile_once( "data/scripts/lib/coroutines.lua" )
-- end

local MAXDIST = 300.0
local IMSCALE = 256.0 * 0.9
local SAFETY_OFFSET = 5.0
local MIN_VISION_DIST = 25.0
local PENETRATION = 5.0
local IMANGLE = math.pi*2.0 / 32

local function get_player()
  return EntityGetWithTag("player_unit")[1]
end

local function make_vision_wedges(count)
  local wedge_angle = math.pi * 2.0 / count
  local ymult = math.tan(wedge_angle/2.0) / math.tan(IMANGLE/2.0)
  print("ROGUEVISION: ymult = ", ymult)

  count = count or 16
  local wedges = {}
  for idx = 1, count do
    local theta = math.pi * 2.0 * (idx-1) / count
    local wedge = EntityLoad("data/roguevision/vision_wedge.xml", 0, 0)
    EntityAddChild(get_player(), wedge)
    local inherit_comp = EntityGetFirstComponent(wedge, "InheritTransformComponent")
    ComponentSetValue(inherit_comp, "only_position", "1")
    EntitySetTransform(wedge, 0, 0, theta)
    local sprite = EntityGetFirstComponent(wedge, "SpriteComponent")
    table.insert(wedges, {ent=wedge, theta=theta, sprite=sprite, ymult=ymult})
  end
  return wedges
end

local function trace_wedge(cx, cy, wedge)
  local sx = cx + math.cos(wedge.theta)*SAFETY_OFFSET
  local sy = cy + math.sin(wedge.theta)*SAFETY_OFFSET
  local tx = cx + math.cos(wedge.theta)*MAXDIST
  local ty = cy + math.sin(wedge.theta)*MAXDIST
  local hit, hitx, hity = Raytrace(sx, sy, tx, ty)
  if not hit then
    hitx = tx
    hity = ty
  end
  local hitdist = ((hitx - cx)^2.0 + (hity - cy)^2.0)^0.5
  hitdist = math.max(hitdist + PENETRATION, MIN_VISION_DIST)
  local scale = hitdist / IMSCALE
  ComponentSetValue(wedge.sprite, "special_scale_x", tostring(scale))
  ComponentSetValue(wedge.sprite, "special_scale_y", tostring(scale * wedge.ymult))
end

local function trace_vision(wedges, decimate, phase)
  local player = get_player()
  if not player then return end
  local cx, cy = EntityGetTransform(player)
  for idx, wedge in ipairs(wedges) do
    if (idx + phase) % decimate == 0 then
      trace_wedge(cx, cy, wedge)
    end
  end
end

local function delete_existing_wedges()
  local ents = EntityGetWithTag("roguevision")
  print("Deleting ", #ents, " existing vision wedges")
  for _, ent in ipairs(ents) do EntityKill(ent) end
end

delete_existing_wedges()
local _vision_wedges = make_vision_wedges(128)

local frame = 0
function _rogue_vision_main()
  frame = frame + 1
  if _vision_wedges then trace_vision(_vision_wedges, 4, frame) end
end


