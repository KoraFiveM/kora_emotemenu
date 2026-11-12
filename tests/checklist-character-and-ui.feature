# Converted from the communitybot legacy tests by kora-qa-panel/scripts/convert-legacy.mjs.
# The """ block under each Scenario is the original test text, verbatim. Review before applying.
Feature: kora_emotemenu — Character & UI

  @kora_emotemenu @checklist @checklist:kora_emotemenu:open-menu-key @cat:character-and-ui
  Scenario: Open emote menu with F3
    """
    Checklist test: Press F3 (rebindable) to open the radial menu with categories General, Dances, Props, Scenarios, Shared.
    """
    When I press the "F3" key
    Then I confirm: the radial menu opens with the categories General, Dances, Props, Scenarios and Shared

  @kora_emotemenu @checklist @checklist:kora_emotemenu:emotes-command @cat:character-and-ui
  Scenario: /emotes opens menu
    """
    Checklist test: Type /emotes to open the menu.
    """
    When I run the command "/emotes"
    Then I confirm: the emote menu opens

  @kora_emotemenu @checklist @checklist:kora_emotemenu:play-emote-command @cat:character-and-ui
  Scenario: /e <name> plays emote
    """
    Checklist test: Run /e wave, /e dance, /e coffee etc.; unknown name shows an error; /e alone opens the menu.
    """
    When I run the command "/e"
    Then I confirm: the emote menu opens
    When I manually: run /e wave
    Then I confirm: my character plays the wave emote
    When I manually: run /e dance
    Then I confirm: my character plays the dance emote
    When I manually: run /e coffee
    Then I confirm: my character plays the coffee emote with a coffee prop
    When I manually: run /e with a name that does not exist
    Then I should see an error notification

  @kora_emotemenu @checklist @checklist:kora_emotemenu:cancel-emote @cat:character-and-ui
  Scenario: Cancel emote (X or /cancel)
    """
    Checklist test: While an emote plays press X or type /cancel to stop it; a 'Cancel emote' hint shows for looping/prop emotes.
    """
    When I manually: play a looping or prop emote such as /e coffee
    Then the text UI should show "Cancel emote"
    When I press the "X" key
    Then I confirm: the emote stops and the hint disappears
    When I manually: play an emote again
    And I run the command "/cancel"
    Then I should see a notification containing "Emote cancelled."
    And I confirm: the emote stops

  @kora_emotemenu @checklist @checklist:kora_emotemenu:general-emotes @cat:character-and-ui
  Scenario: General emotes: wave, salute, hands up
    """
    Checklist test: Play Wave, Salute, Hands up; with Hands up you can still walk but not sprint, jump, aim or shoot.
    """
    When I press the "F3" key
    And I manually: play Wave from General
    Then I confirm: my character waves
    When I manually: play Salute from General
    Then I confirm: my character salutes
    When I manually: play Hands up from General
    Then I confirm: my character can walk with hands up
    And I confirm: I cannot sprint, jump, aim or shoot while hands are up

  @kora_emotemenu @checklist @checklist:kora_emotemenu:dance-emotes @cat:character-and-ui
  Scenario: Dance emotes
    """
    Checklist test: Play Air guitar, Dance, Dance 2 from the Dances category.
    """
    When I press the "F3" key
    And I manually: play Air guitar from Dances
    Then I confirm: my character plays the Air guitar animation
    When I manually: play Dance from Dances
    Then I confirm: my character plays the Dance animation
    When I manually: play Dance 2 from Dances
    Then I confirm: my character plays the Dance 2 animation

  @kora_emotemenu @checklist @checklist:kora_emotemenu:prop-emotes @cat:character-and-ui
  Scenario: Prop emotes: clipboard, coffee
    """
    Checklist test: Play Clipboard and Coffee; the prop attaches to the hand and is removed when cancelled.
    """
    When I press the "F3" key
    And I manually: play Clipboard from Props
    Then I confirm: a clipboard prop is attached to my hand
    When I run the command "/cancel"
    Then I confirm: the clipboard prop is removed
    When I manually: play Coffee from Props
    Then I confirm: a coffee prop is attached to my hand
    When I run the command "/cancel"
    Then I confirm: the coffee prop is removed

  @kora_emotemenu @checklist @checklist:kora_emotemenu:scenario-emotes @cat:character-and-ui
  Scenario: Scenario emotes: sit, lean
    """
    Checklist test: Play Sit / Lean scenarios from the Scenarios category (refused when in a vehicle).
    """
    When I press the "F3" key
    And I manually: play Sit from Scenarios
    Then I confirm: my character plays the sit scenario
    When I manually: play Lean from Scenarios
    Then I confirm: my character plays the lean scenario
    When I manually: get into a vehicle and try a scenario emote
    Then I confirm: the scenario is refused while I am in a vehicle

  @kora_emotemenu @checklist @checklist:kora_emotemenu:shared-emotes @cat:character-and-ui
  Scenario: Shared emotes: handshake, hug
    """
    Checklist test: Stand within 3m of another player, pick Handshake/Hug; they get an accept/decline prompt, both play matching animations.
    """
    When I manually: ask a second player to stand within 3 metres of me
    And I press the "F3" key
    And I manually: pick Handshake from Shared
    Then I confirm: the other player gets an accept/decline prompt
    When I manually: ask the second player to accept
    Then I confirm: both players play matching handshake animations
    When I manually: pick Hug from Shared and ask the second player to accept
    Then I confirm: both players play matching hug animations

  @kora_emotemenu @checklist @checklist:kora_emotemenu:walk-styles @cat:character-and-ui
  Scenario: Walk styles (menu or /walk)
    """
    Checklist test: Pick a walk (Brave, Casual, Confident, Drunk, Hurry, Sad) or /walk <name>; /walk alone resets; active style marked, persists.
    """
    When I press the "F3" key
    And I manually: pick the Brave walk style
    Then I confirm: my walk changes to Brave
    And I confirm: the Brave entry is marked as Currently active
    When I manually: try Casual, Confident, Drunk, Hurry and Sad in turn
    Then I confirm: each walk style applies
    When I run the command "/walk"
    Then I confirm: my walk is reset to Default
    When I manually: run /walk drunk
    Then I should see a notification containing "Walk style:"
    When I manually: relog or reconnect and check my walk style
    Then I confirm: my walk style persists (only applies when Config.persistAppearance is enabled)

  @kora_emotemenu @checklist @checklist:kora_emotemenu:expressions @cat:character-and-ui
  Scenario: Facial expressions (menu or /expression)
    """
    Checklist test: Pick Angry/Happy/Smug/Stressed or /expression <name>; /expression resets to default; persists across restarts.
    """
    When I press the "F3" key
    And I manually: pick the Angry expression
    Then I confirm: my face shows an angry expression
    When I manually: try Happy, Smug and Stressed in turn
    Then I confirm: each expression applies
    When I manually: run /expression happy
    Then I should see a notification containing "Expression:"
    When I run the command "/expression"
    Then I confirm: my expression is reset to Default
    When I manually: set an expression and reconnect
    Then I confirm: my expression persists (only applies when Config.persistAppearance is enabled)

  @kora_emotemenu @checklist @checklist:kora_emotemenu:vehicle-emotes @cat:character-and-ui
  Scenario: Emotes while in a vehicle
    """
    Checklist test: In a seat, animations play upper-body only without leaving the seat; scenarios, shared and walk changes are refused.
    """
    Given I am in the driver seat of a "test_car"
    When I manually: play an animation emote such as Wave
    Then I confirm: the animation plays on the upper body only
    And I should be in the driver seat
    When I manually: try a scenario emote
    Then I should see a notification containing "You cannot use emotes right now."
    When I manually: try a shared emote
    Then I confirm: the shared emote is refused with a notification
    When I manually: try to change my walk style
    Then I confirm: the walk change is refused (only applies when Config.vehicle.upperBodyOnly is enabled)

  @kora_emotemenu @checklist @checklist:kora_emotemenu:cuffed-block @cat:character-and-ui
  Scenario: Cuffed players cannot emote
    """
    Checklist test: While handcuffed, emote menu/ /e is blocked and a running emote is cancelled at the moment of cuffing.
    """
    When I manually: ask a second player or police to handcuff me
    And I press the "F3" key
    And I manually: try to play an emote
    Then I confirm: the emote is blocked
    When I run the command "/e"
    Then I confirm: no emote plays while cuffed
    When I manually: get uncuffed and start a looping emote
    And I manually: ask a second player to handcuff me while the emote is running
    Then I confirm: the running emote is cancelled the moment I am cuffed (only applies when Config.blockWhenCuffed is enabled)

  @kora_emotemenu @checklist @checklist:kora_emotemenu:emote-maker @cat:character-and-ui @needs:admin
  Scenario: /emoteMaker admin emote creator
    """
    Checklist test: Admin runs /emoteMaker: freecam editor to build emotes with anim dict/clip and props; non-admins get a permission error.
    """
    When I manually: as an admin, run /emoteMaker
    Then I confirm: the freecam emote editor opens
    When I manually: enter an animation dict and clip and add a prop
    Then I confirm: the preview plays the animation and prop
    When I manually: as a non-admin, run /emoteMaker
    Then I should see a notification containing "You do not have permission"

  @kora_emotemenu @checklist @checklist:kora_emotemenu:uncuff-emote @cat:character-and-ui
  Scenario: Created 'Uncuff' emote in catalogue
    """
    Checklist test: The saved 'Uncuff' emote (mp_arresting a_uncuff) appears in General emotes and plays via /e uncuff.
    """
    When I press the "F3" key
    And I manually: open the General category
    Then I confirm: a saved 'Uncuff' emote appears in General
    When I manually: run /e uncuff
    Then I confirm: my character plays the mp_arresting a_uncuff animation
