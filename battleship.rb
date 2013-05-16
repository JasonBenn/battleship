require 'pp'

class Cell
  attr_accessor :state, :ship, :board
  
  def initialize(board)
    @state = "water"
    @board = board
  end

  def ai?
    board.name == 'COMPUTER'
  end

  def show
    return '.' if @state == "water"
    return '/' if @state == "miss"
    return 'X' if @state == "hit"
    return ai? ? '.' : ('O' if @state == "alive")
  end

  def to_ship(ship)
    @state = "alive"
    @ship = ship
  end

  def attack
    if @state == "alive"
      @state = "hit" 
      board.boats[ship] -= 1
      # board.check_sunk?
      if ai?
        return "HIT!!"
      else
        return "#{board.name}'S' #{ship.upcase} HIT! Remaining health: #{board.boats[ship]}"
      end
    elsif @state == "hit"
      return "Already attacked this spot..."
    else
      @state = "miss"
      return "Miss!"
    end
  end
end

class Board
  attr_accessor :board, :nav, :name, :boats
  def initialize(name)
    @name = name
    @board = Array.new(10) { Array.new(10) { Cell.new(self) } }
    @boats = {
      carrier_one: 5
      # battleship_one: 4,
      # cruiser_one: 3
      # destroyer_one: 2, 
      # destroyer_two: 2, 
      # submarine_one: 1, 
      # submarine_one: 1
    }
  end

  #Insert kill boat message.

  def live_boats
    boats.select { |_, health| health > 0 }.count
  end

  def check_sunk?
    live_boats == 0 ? lose_game : ""
  end

  def show
    puts "#{name.upcase}:".center(24)
    puts
    rows = ('A'..'J').to_a
    puts "    1 2 3 4 5 6 7 8 9 10"
    puts
    board.each do |row|
      print rows.shift.to_s.ljust(4, ' ')
      row.each do |cell|
        print cell.show, ' '
      end
      puts
    end
    puts
  end


  def place
    @boats.each do |boat, boat_length|
      puts "Place #{name}s' #{boat} of length #{boat_length}:"
      top_left = gets.chomp.upcase
      puts "Should it be placed (h)orizontally or (v)ertically?"
      direction = gets.chomp

      1.upto boat_length do 
        x, y = nav.find(top_left, self)
        board[x][y].to_ship(boat)

        if direction =~ /^H/i
          top_left = top_left.succ
        elsif direction =~ /^V/i
          top_left = top_left.reverse.succ.reverse
        end
      end
      print "\e[2J\e[f"
      show
      puts "Ship placed!"
    end
  end

  def lose_game
    puts "#{name.upcase}'S FINAL SHIP SUNK!! GAME OVER"
    puts "*cheering* *credits*"
    exit
  end
end

class AIPlayer
  def choose
    x, y = rand(10), rand(10)
    to_coordinate(x, y)
  end

  def to_coordinate(x, y)
    hash = { A: 0, B: 1, C: 2, D: 3, E: 4, F: 5, G: 6, H: 7, I: 8, J: 9 }    
    letter = hash.key(x)
    number = y + 1
    "#{letter}#{number}"
  end
end

class HumanPlayer
  def choose
    until valid?(input ||= '')
      puts "Your orders, Commander:"
      input = gets.chomp
      puts "Perhaps we should aim for the board, sir!" unless valid?(input)
    end
    input
  end

  def valid?(input = nil)
    return false if input.nil?
    valid_letters = ('a'..'j').to_a + ('A'..'J').to_a
    valid_letters.include? input[0] and ('1'..'10').include? input[1..-1]
  end
end

class Navigator
  attr_accessor :human, :ai, :human_player, :ai_player
  def initialize(human, ai)
    @human = human
    @ai = ai
    @human_player = HumanPlayer.new
    @ai_player = AIPlayer.new
  end

  def play
    {human_player => [human, ai], ai_player => [ai, human]}.cycle do |player, (player_board, enemy_board)|
      puts "You have #{player_board.boats.count} torpedoes ready." if player == human_player
      messages = []
      player_board.live_boats.times do
        target = player.choose
        x, y, action_string = find(target, player_board)
        reaction_string = enemy_board.board[x][y].attack
        messages << action_string + reaction_string
      end
      print "\e[2J\e[f"
      ai.show
      human.show
      puts messages
      [ai, human].each { |b| b.check_sunk? }

      puts "End of #{player_board.name}'s turn."
      if player.class == HumanPlayer
        puts "Press enter to continue"
        next if gets == "\n"
      end
    end
  end
  
  def show
    print "\e[2J\e[f"
    human.show
    puts
    ai.show
  end

  def find(input, board)
    board = [human, ai].select { |b| b == board }
    hash = { A: 0, B: 1, C: 2, D: 3, E: 4, F: 5, G: 6, H: 7, I: 8, J: 9 }    
    x = hash[input[0].upcase.to_sym].to_i
    y = input[1..-1].to_i - 1
    return x, y, "#{board[0].name} targets #{input}: "  #BUG: name is backwards.
  end
end

print "\e[2J\e[f"
c = Board.new('COMPUTER')
b = Board.new('YOU')
n = Navigator.new(b, c)
c.nav = n
b.nav = n
c.place
b.place
n.play

__END__

TECHNICAL DEBT CHECKLIST:
-Kill boat message.
-Exploding board!!
-check sunk method: fail condition in ternary operator should display info
 about the # of sunken ships
-placing ships out of bounds is accepted
-AI should cluster shots around hit ships
-Game initialization sequence should suck less
-gosu
