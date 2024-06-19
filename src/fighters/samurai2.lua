return {
    name = 'Samurai2',
    scale = {x = 1.35, y = 1.3, ox = 0, oy = -2, width = 50, height = 80},
    traits = {health = 1, speed = 185, stamina = 100, dashSpeed = 515, jumpStrength = 600},
    hitboxes = {
        light = {width = 90, height = 100, recovery = 0.2, damage = 8},
        medium = {width = 90, height = 130, recovery = 0.4, damage = 12},
        heavy = {width = 90, height = 130, recovery = 0.7, damage = 24}
    },
    spriteConfig = {
        idle = {path = 'assets/fighters/Samurai2/Idle.png', frames = 4, frameDuration = {0.1, 0.1, 0.1, 0.1}},
        run = {
            path = 'assets/fighters/Samurai2/Run.png',
            frames = 8,
            frameDuration = {0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1}
        },
        jump = {path = 'assets/fighters/Samurai2/Jump.png', frames = 2, frameDuration = {0.1, 0.1}},
        light = {path = 'assets/fighters/Samurai2/Attack1.png', frames = 4, frameDuration = {0.1, 0.1, 0.1, 0.1}},
        medium = {path = 'assets/fighters/Samurai2/Attack2.png', frames = 4, frameDuration = {0.1, 0.1, 0.1, 0.1}},
        heavy = {path = 'assets/fighters/Samurai2/Attack2.png', frames = 4, frameDuration = {0.1, 0.1, 0.1, 0.1}},
        hit = {path = 'assets/fighters/Samurai2/TakeHit.png', frames = 3, frameDuration = {0.1, 0.1, 0.1}},
        death = {
            path = 'assets/fighters/Samurai2/Death.png',
            frames = 7,
            frameDuration = {0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1}
        }
    },
    soundFXConfig = {
        light = 'assets/fighters/Samurai2/Attack1.wav',
        medium = 'assets/fighters/Samurai2/Attack1.wav',
        heavy = 'assets/fighters/Samurai2/Attack1.wav',
        hit = 'assets/fighters/Samurai2/Hit.mp3',
        block = 'assets/fighters/Samurai2/Block.wav',
        jump = 'assets/fighters/Samurai2/Jump.mp3',
        dash = 'assets/fighters/Samurai2/Dash.mp3',
        death = 'assets/fighters/Samurai2/Death.mp3'
    }
}
