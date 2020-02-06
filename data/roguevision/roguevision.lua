-- -- try to use better ws coroutines first
-- dofile_once("data/ws/coroutines.lua")
-- if not async then
--   dofile_once( "data/scripts/lib/coroutines.lua" )
-- end

local MAXDIST = 300.0
local IMSCALE = 256.0 * 0.9
local SAFETY_OFFSET = 5.0
local MIN_VISION_DIST = 50.0
local PENETRATION = 5.0
local IMANGLE = math.pi*2.0 / 128
local SPECKLE_THRESH = 100.0

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
    table.insert(wedges, {
      ent=wedge, 
      theta=theta, 
      sprite=sprite, 
      ymult=ymult, 
      dist=MIN_VISION_DIST
    })
  end
  return wedges
end

local function delete_existing_wedges()
  local ents = EntityGetWithTag("roguevision")
  print("Deleting ", #ents, " existing vision wedges")
  for _, ent in ipairs(ents) do EntityKill(ent) end
end

local _vision_wedges = nil
local WEDGE_COUNT = 0

local function recreate_wedges()
  delete_existing_wedges()
  _vision_wedges = make_vision_wedges(256)
  WEDGE_COUNT = #_vision_wedges
end

local function get_neighbor_dists(idx)
  return _vision_wedges[((idx-2)%WEDGE_COUNT)+1].dist, 
         _vision_wedges[(idx%WEDGE_COUNT)+1].dist
end

local function trace_wedge(cx, cy, wedge_idx)
  local wedge = _vision_wedges[wedge_idx]
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
  wedge.dist = hitdist
  -- local d_left, d_right = get_neighbor_dists(wedge_idx)
  -- if math.max(math.abs(hitdist - d_left), math.abs(hitdist - d_right)) > SPECKLE_THRESH then
  --   hitdist = math.max(d_left, d_right)
  -- end

  local scale = hitdist / IMSCALE
  ComponentSetValue(wedge.sprite, "special_scale_x", tostring(scale))
  ComponentSetValue(wedge.sprite, "special_scale_y", tostring(scale * wedge.ymult))
end

local function trace_vision(decimate, phase)
  local player = get_player()
  if not player then
    _vision_wedges = nil
    WEDGE_COUNT = 0
    return 
  end
  if not _vision_wedges then
    recreate_wedges()
  end
  local cx, cy = EntityGetTransform(player)
  for idx = 1, WEDGE_COUNT do
    if (idx + phase) % decimate == 0 then
      trace_wedge(cx, cy, idx)
    end
  end
end

local frame = 0
function _rogue_vision_main()
  frame = frame + 1
  trace_vision(2, frame)
end


