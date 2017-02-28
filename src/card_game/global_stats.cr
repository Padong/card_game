module CardGame

  class GameStat < Lattice::Connected::WebObject
    property players : String?
    property connections = 0
    property game : String?
    property last_connected : String?

    def set(@game, @connections, @players, @last_connected)
      if (card_game = CardGame.find( game ) )
        card_game.add_observer(self)
      end
    end

    #FIXME need a update_or_create
    def on_event( event, speaker )
      if ["subscribed"].includes? event.event_type
        sockets = @creator.as(Lattice::Connected::WebObject).subscribers
        @creator.as(Lattice::Connected::DynamicBuffer).add_or_update_content self
      end
    end

    def value
      render "./src/card_game/game_stat_value.slang"
    end

    def content
      render "./src/card_game/game_stat.slang"
    end

  end

  #class GlobalStats < Lattice::Connected::DynamicBuffer
  class GlobalStats < Lattice::Connected::ObjectList

    def update_users
      update_stats
      update({"id"=>dom_id, "value"=>content})
    end

    def update_stats
      sql = "select game, group_concat(distinct player), 
        count(*),
        max(datetime(started,'unixepoch','localtime'))
        from player_game
        group by game
        order by started desc
        limit #{@max_items}"

      Storage.connection.query(sql) do |rs|
        rs.each do
          game = rs.read(String)
          players = rs.read(String)
          connections = rs.read(Int32)
          last_connected = rs.read(String)
          item = GameStat.child_of(self, "#{dom_id}-#{game}" )
          item.set game, connections, players, last_connected

          @items << item
        end
      end
    end
  end
end
