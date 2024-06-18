return {
    name = 'Samurai2',
    scale = {x = 1.35, y = 1.3, ox = 0, oy = -2, width = 50 , height = 80},
    traits = {health = 120, speed = 185, stamina = 100, dashSpeed = 515, jumpStrength = 600},
    hitboxes = {
        light = {width = 90, height = 100, recovery = 0.25, damage = 8, duration = 0.45},
        medium = {width = 90, height = 130, recovery = 0.4, damage = 12, duration = 0.4},
        heavy = {width = 90, height = 130, recovery = 0.8, damage = 24, duration = 0.8}
    },
    spriteConfig = {
        idle = {'assets/fighters/Samurai2/Idle.png', 4},
        run = {'assets/fighters/Samurai2/Run.png', 8},
        jump = {'assets/fighters/Samurai2/Jump.png', 2},
        light = {'assets/fighters/Samurai2/Attack1.png', 4},
        medium = {'assets/fighters/Samurai2/Attack2.png', 4},
        heavy = {'assets/fighters/Samurai2/Attack2.png', 4},
        hit = {'assets/fighters/Samurai2/TakeHit.png', 3},
        death = {'assets/fighters/Samurai2/Death.png', 7}
    },
    soundFXConfig = {
        light = 'assets/fighters/Samurai2/Attack1.wav',
        medium = 'assets/fighters/Samurai2/Attack1.wav',
        heavy = 'assets/fighters/Samurai2/Attack1.wav',
        hit = 'assets/fighters/Samurai2/Hit.mp3',
        block = 'assets/fighters/Samurai2/Block.wav',
        jump = 'assets/fighters/Samurai2/Jump.mp3',
        dash = 'assets/fighters/Samurai2/Dash.mp3'
    }
}
