import SwiftUI

// MARK: - Data Models & Enums

/// Represents the x/y coordinate on the game grid.
struct Position: Equatable {
    var x: Int
    var y: Int
}

/// Possible movement directions for the snake.
enum Direction {
    case up, down, left, right
}

/// Difficulty level determines the timer interval (game speed).
enum Difficulty: Double, CaseIterable {
    case easy   = 0.4
    case medium = 0.2
    case hard   = 0.1
    
    var label: String {
        switch self {
        case .easy:   return "Easy"
        case .medium: return "Medium"
        case .hard:   return "Hard"
        }
    }
}

// MARK: - ViewModel

/// Holds all game state, including snake position, food, and game logic.
class GameState: ObservableObject {
    @Published var snakeBody: [Position] = [Position(x: 5, y: 5)]
    @Published var food: Position = Position(x: Int.random(in: 0..<10), y: Int.random(in: 0..<10))
    @Published var direction: Direction = .right
    @Published var isGameOver = false
    
    let gridSize = 10

    /// Updates the snake's position and handles collisions/food pickup.
    func update() {
        guard !isGameOver else { return }
        
        // Current head of the snake
        var newHead = snakeBody[0]
        
        // Move head in the current direction
        switch direction {
        case .up:
            newHead.y -= 1
        case .down:
            newHead.y += 1
        case .left:
            newHead.x -= 1
        case .right:
            newHead.x += 1
        }
        
        // Check for collision with walls
        if newHead.x < 0 || newHead.x >= gridSize || newHead.y < 0 || newHead.y >= gridSize {
            isGameOver = true
            return
        }
        
        // Check for collision with snake body
        if snakeBody.contains(newHead) {
            isGameOver = true
            return
        }
        
        // Insert new head
        snakeBody.insert(newHead, at: 0)
        
        // Check if food is eaten
        if newHead == food {
            // Generate new food in a random position not occupied by the snake
            repeat {
                food = Position(x: Int.random(in: 0..<gridSize),
                                y: Int.random(in: 0..<gridSize))
            } while snakeBody.contains(food)
        } else {
            // Remove tail if no food eaten
            snakeBody.removeLast()
        }
    }
}

// MARK: - Main View

struct ContentView: View {
    
    // ObservedObject manages all snake/food logic
    @ObservedObject var gameState = GameState()
    
    // Menu-related state
    @State private var showMenu: Bool = true
    @State private var selectedDifficulty: Difficulty = .medium
    
    // Timer to drive the game updates
    @State private var timer = Timer.publish(every: 0.2, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            // Black background
            Color.black.edgesIgnoringSafeArea(.all)
            
            if showMenu {
                // Difficulty Selection Menu
                VStack(spacing: 40) {
                    Text("Snake Game")
                        .font(.largeTitle)
                        .foregroundColor(.white)
                    
                    // Difficulty Picker
                    VStack(spacing: 20) {
                        Text("Select Difficulty:")
                            .foregroundColor(.white)
                            .font(.headline)
                        
                        Picker("Difficulty", selection: $selectedDifficulty) {
                            ForEach(Difficulty.allCases, id: \\.self) { difficulty in
                                Text(difficulty.label).tag(difficulty)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .padding(.horizontal, 40)
                    }
                    
                    // Start Button
                    Button(action: {
                        startGame()
                    }) {
                        Text("Start")
                            .font(.title2)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
            } else if gameState.isGameOver {
                // Game Over Screen
                VStack {
                    Text("Game Over!")
                        .foregroundColor(.white)
                        .font(.largeTitle)
                        .padding(.bottom, 30)
                    
                    Text("Tap to Restart")
                        .foregroundColor(.white)
                        .font(.headline)
                }
                .onTapGesture {
                    restartGame()
                }
            } else {
                // Main Game View
                VStack {
                    Text("Snake Game")
                        .foregroundColor(.white)
                        .font(.title2)
                        .padding()
                    
                    Spacer()
                    
                    // The board is a square grid
                    GeometryReader { geometry in
                        let cellWidth  = geometry.size.width / CGFloat(gameState.gridSize)
                        let cellHeight = geometry.size.height / CGFloat(gameState.gridSize)
                        
                        ZStack {
                            // Snake Body
                            ForEach(0..<gameState.snakeBody.count, id: \\.self) { index in
                                let segment = gameState.snakeBody[index]
                                Rectangle()
                                    .fill(Color.green)
                                    .frame(width: cellWidth, height: cellHeight)
                                    .position(
                                        x: CGFloat(segment.x) * cellWidth + cellWidth / 2,
                                        y: CGFloat(segment.y) * cellHeight + cellHeight / 2
                                    )
                            }
                            
                            // Food
                            Rectangle()
                                .fill(Color.red)
                                .frame(width: cellWidth, height: cellHeight)
                                .position(
                                    x: CGFloat(gameState.food.x) * cellWidth + cellWidth / 2,
                                    y: CGFloat(gameState.food.y) * cellHeight + cellHeight / 2
                                )
                        }
                    }
                    .aspectRatio(1, contentMode: .fit)
                    Spacer()
                }
            }
        }
        // Updates the game on each timer tick
        .onReceive(timer) { _ in
            if !showMenu && !gameState.isGameOver {
                withAnimation(.linear(duration: 0.15)) {
                    gameState.update()
                }
            }
        }
        // Gesture for controlling snake direction
        .gesture(
            DragGesture()
                .onChanged { value in
                    let horizontalAmount = value.translation.width
                    let verticalAmount = value.translation.height
                    
                    if abs(horizontalAmount) > abs(verticalAmount) {
                        // Horizontal drag
                        if horizontalAmount < 0 {
                            if gameState.direction != .right {
                                gameState.direction = .left
                            }
                        } else {
                            if gameState.direction != .left {
                                gameState.direction = .right
                            }
                        }
                    } else {
                        // Vertical drag
                        if verticalAmount < 0 {
                            if gameState.direction != .down {
                                gameState.direction = .up
                            }
                        } else {
                            if gameState.direction != .up {
                                gameState.direction = .down
                            }
                        }
                    }
                }
        )
    }
    
    // MARK: - Methods
    
    /// Configure and start a new game by hiding the menu and setting the timer speed.
    private func startGame() {
        showMenu = false
        setTimerSpeed()
    }
    
    /// Restart the game after a game-over.
    private func restartGame() {
        gameState.snakeBody = [Position(x: 5, y: 5)]
        gameState.food = Position(x: Int.random(in: 0..<gameState.gridSize),
                                  y: Int.random(in: 0..<gameState.gridSize))
        gameState.direction = .right
        gameState.isGameOver = false
        
        setTimerSpeed()
    }
    
    /// Update the timer interval based on the chosen difficulty.
    private func setTimerSpeed() {
        timer = Timer.publish(every: selectedDifficulty.rawValue, on: .main, in: .common).autoconnect()
    }
}

// MARK: - App Entry Point

@main
struct SnakeGameApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

