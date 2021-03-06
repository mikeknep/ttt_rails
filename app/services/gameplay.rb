class Gameplay
  require 'set'

  def initialize(params)
    @game = Game.find(params[:id])
    @position = params[:position].to_i
    whos_who
  end

  def play_turns
    human_turn
    computer_turn if @game.spots.where(player: nil).count > 0
  end

  def check_status
    assess_board
    @game.status = "draw" if @game.spots.where(player: nil).empty?
    @all_victories.each { |victory_set| @game.status = 'loss' if victory_set.subset?(@computer_spots) }
    @game.save
  end


  private


  def whos_who
    @human_player_number = @game.spots.where.not(player: nil).count.even? ? 1 : 2
    @computer_player_number = @game.spots.where.not(player: nil).count.even? ? 2 : 1
  end

  def assess_board
    @computer_spots = @game.spots.where(player: @computer_player_number).map{ |s| s.position }.to_set
    @human_spots = @game.spots.where(player: @human_player_number).map{ |s| s.position }.to_set
    @all_victories = [[1,2,3], [4,5,6], [7,8,9], [1,4,7], [2,5,8], [3,6,9], [1,5,9], [3,5,7]].map{ |a| a.to_set }
  end

  def human_turn
    spot = @game.gamespot(@position)
    spot.update_attribute(:player, @human_player_number)
  end

  def computer_turn
    spot = determine_next_spot
    spot.update_attribute(:player, @computer_player_number)
  end

  def determine_next_spot
    assess_board

    # Play the first available spot on the board
    next_move = @game.spots.where(player: nil).first

    # Overwrite for advanced logic pertaining to the first move that follows a human move (computer's first or second depending on who went first)
    if @game.spots.where.not(player: nil).count < 3
      if @game.gamespot(5).player.nil?
        next_move = @game.gamespot(5)
      elsif @game.gamespot(1).player.nil?
        next_move = @game.gamespot(1)
      else
        next_move = @game.gamespot(2)
      end
    end

    # Overwrite if computer needs to block opponent from winning
    @all_victories.each do |victory_set|
      if (victory_set - @human_spots).count == 1
        if @game.gamespot((victory_set - @human_spots).first).player.nil?
          next_move = @game.gamespot((victory_set - @human_spots).first)
        end
      end
    end

    # Overwrite if a winning spot is available to the computer
    @all_victories.each do |victory_set|
      if (victory_set - @computer_spots).count == 1
        if @game.gamespot((victory_set - @computer_spots).first).player.nil?
          next_move = @game.gamespot((victory_set - @computer_spots).first)
        end
      end
    end

    return next_move
  end

end
