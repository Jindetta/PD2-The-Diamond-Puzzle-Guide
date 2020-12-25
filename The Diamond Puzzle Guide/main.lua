if Global.level_data and Global.level_data.level_id == "mus" then
    if not TDPGMod then
        local hook_name = Network:is_server() and "on_executed" or "client_on_executed"
        TDPGMod = {_brush = Draw:brush()}

        function TDPGMod:set_highlight_mode(highlight_mode)
            if self._highlight_mode ~= highlight_mode then
                self._highlight_mode = highlight_mode

                if highlight_mode == "critical" then
                    self._brush:set_color(Color(0.05, 1, 0, 0))  -- <= 5 seconds
                elseif highlight_mode == "warning" then
                    self._brush:set_color(Color(0.05, 1, 1, 0))  -- <= 10 seconds
                else
                    self._brush:set_color(Color(0.05, 0, 1, 0))  -- > 10 seconds
                end
            end
        end

        function TDPGMod:init()
            if RequiredScript == "core/lib/managers/coreworldinstancemanager" then
                Hooks:PostHook(CoreWorldInstanceManager, "add_instance_data", "TDPG_AddInstanceData", function(manager, instance)
                    if instance.name:match("^mus_tile_[a-i]00[1-6]$") then
                        local base_index = instance.start_index + manager:start_offset_index()
                        self.tile_data[instance.name] = base_index + 100001
                    end
                end)
            elseif RequiredScript == "lib/managers/missionmanager" then
                function TDPGMod:add_drawable(instance)
                    if type(self.drawn_tiles) == "table" then
                        local instance_id = self.tile_data[instance]
                        local element = managers.mission:get_element_by_id(instance_id)

                        if type(element) == "table" then
                            local shape = element._shapes[1]

                            if type(shape) == "table" then
                                local rot = shape:rotation()

                                table.insert(self.drawn_tiles, {
                                    pos = shape:position() - rot:z() * (shape._properties.height - 20) / 2,
                                    width = rot:x() * shape._properties.width / 2,
                                    depth = rot:y() * shape._properties.depth / 2,
                                    height = Vector3(0, 0, -1)
                                })
                            end
                        end
                    end
                end

                --[[function TDPGMod:post_path()
                    local forward_steps = 9
                    local path_string, previous_y = ""

                    if #self.drawn_tiles >= forward_steps then
                        for _, tile in ipairs(self.drawn_tiles) do
                            if not previous_y or previous_y == tile.pos.y then
                                forward_steps = forward_steps - 1
                                path_string = path_string .. "w"
                            elseif previous_y < tile.pos.y then
                                path_string = path_string .. "a"
                            elseif previous_y > tile.pos.y then
                                path_string = path_string .. "d"
                            end

                            previous_y = tile.pos.y
                        end

                        if managers.chat and forward_steps <= 0 then
                            managers.chat:send_message(ChatManager.GAME, Steam:username(), path_string)
                        end
                    end
                end--]]

                Hooks:PostHook(MissionScriptElement, "init", "TDPG_InitTiles", function(element, _, data)
                    if data.editor_name:match("^disable_[a-i]00[1-6]$") then
                        Hooks:PostHook(element, hook_name, "TDPG_HighlightTile", function()
                            self:add_drawable(data.values.event_list[1].instance)
                        end)
                    elseif data.id == 101517 then
                        Hooks:PostHook(element, hook_name, "TDPG_ClearAllTiles", function()
                            self.drawn_tiles = {}
                        end)
                    elseif data.id == 101784 then
                        Hooks:PostHook(element, hook_name, "TDPG_GasTriggered", function()
                            Hooks:RemovePostHook("TDPG_UpdateDigitalGui")
                            Hooks:RemovePostHook("TDPG_HighlightTile")
                            Hooks:RemovePostHook("TDPG_UpdateTiles")
                            self.drawn_tiles = nil
                        end)
                    end
                end)

                Hooks:PostHook(MissionScript, "update", "TDPG_UpdateTiles", function()
                    for _, tile in ipairs(self.drawn_tiles or {}) do
                        self._brush:box(tile.pos, tile.width, tile.depth, tile.height)
                    end
                end)
            else
                Hooks:PostHook(DigitalGui, "init", "TDPG_InitDigitalGui", function(gui, unit)
                    if alive(unit) and unit:name():key() == "5a7e636bc31e53b2" then
                        Hooks:PostHook(gui, "_update_timer_text", "TDPG_UpdateDigitalGui", function()
                            if gui._timer > 0 and gui._timer <= 5 then
                                self:set_highlight_mode("critical")
                            elseif gui._timer > 0 and gui._timer <= 10 then
                                self:set_highlight_mode("warning")
                            elseif gui._timer > 0 then
                                self:set_highlight_mode("cool")
                            end
                        end)

                        self:set_highlight_mode("cool")
                    end
                end)
            end
        end

        TDPGMod.drawn_tiles = {}
        TDPGMod.tile_data = {}
    end

    TDPGMod:init()
end