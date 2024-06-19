-- Core
_G.KeyMappings  = require 'keymap'
_G.Class        = require 'lib.class'
_G.AIController = require 'ai.aicontroller'
_G.SoundManager = require 'sound.soundmanager'
-- Entities
_G.Fighter = require 'entities.fighter'
-- States
_G.StateMachine    = require 'states.statemachine'
_G.Menu            = require 'states.menu'
_G.Loading         = require 'states.loading'
_G.Game            = require 'states.game'
_G.CharacterSelect = require 'states.characterselect'
_G.Settings        = require 'states.settings'
