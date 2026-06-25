import MahjongKit

print("""
╔════════════════════════════════════════╗
║       台灣十六張麻將  CLI 版           ║
║  1人 vs 3AI  |  按 Enter 開始遊戲     ║
╚════════════════════════════════════════╝
""")
_ = readLine()

let engine = GameEngine()
engine.run()
