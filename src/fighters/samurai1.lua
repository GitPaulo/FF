return {
    name = 'Samurai1',
    scale = {x = 1.35, y = 1.3, ox = 0, oy = 4, width = 50, height = 80},
    traits = {health = 100, speed = 200, stamina = 100, dashSpeed = 600, jumpStrength = 600},
    hitboxes = {
        light = {width = 95, height = 100, recovery = 0.2, damage = 7},
        medium = {width = 100, height = 25, recovery = 0.5, damage = 12},
        heavy = {width = 100, height = 25, recovery = 0.8, damage = 20}
    },
    spriteConfig = {
        idle = {
            path = 'assets/fighters/Samurai1/Idle.png',
            frames = 8,
            frameDuration = {0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1}
        },
        run = {
            path = 'assets/fighters/Samurai1/Run.png',
            frames = 8,
            frameDuration = {0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1}
        },
        jump = {path = 'assets/fighters/Samurai1/Jump.png', frames = 2, frameDuration = {0.1, 0.1}},
        light = {
            path = 'assets/fighters/Samurai1/Attack1.png',
            frames = 6,
            frameDuration = {0.1, 0.1, 0.1, 0.1, 0.1, 0.1}
        },
        medium = {
            path = 'assets/fighters/Samurai1/Attack2.png',
            frames = 6,
            frameDuration = {0.1, 0.1, 0.1, 0.1, 0.1, 0.1}
        },
        heavy = {
            path = 'assets/fighters/Samurai1/Attack2.png',
            frames = 6,
            frameDuration = {0.1, 0.1, 0.1, 0.1, 0.1, 0.1}
        },
        hit = {path = 'assets/fighters/Samurai1/TakeHit.png', frames = 4, frameDuration = {0.1, 0.1, 0.1, 0.1}},
        death = {
            path = 'assets/fighters/Samurai1/Death.png',
            frames = 6,
            frameDuration = {0.1, 0.1, 0.1, 0.1, 0.1, 0.1}
        }
    },
    soundFXConfig = {
        light = 'assets/fighters/Samurai1/Attack1.wav',
        medium = 'assets/fighters/Samurai1/Attack1.wav',
        heavy = 'assets/fighters/Samurai1/Attack1.wav',
        hit = 'assets/fighters/Samurai1/Hit.mp3',
        block = 'assets/fighters/Samurai1/Block.wav',
        jump = 'assets/fighters/Samurai1/Jump.mp3',
        dash = 'assets/fighters/Samurai1/Dash.mp3',
        death = 'assets/fighters/Samurai1/Death.mp3'
    }
}
