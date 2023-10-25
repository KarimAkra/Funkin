package funkin.modding.events;

import funkin.data.song.SongData.SongNoteData;
import flixel.FlxState;
import flixel.FlxSubState;
import funkin.play.notes.NoteSprite;
import funkin.play.cutscene.dialogue.Conversation;
import funkin.play.Countdown.CountdownStep;
import funkin.play.notes.NoteDirection;
import openfl.events.EventType;
import openfl.events.KeyboardEvent;

/**
 * This is a base class for all events that are issued to scripted classes.
 * It can be used to identify the type of event called, store data, and cancel event propagation.
 */
class ScriptEvent
{
  /**
   * If true, the behavior associated with this event can be prevented.
   * For example, cancelling COUNTDOWN_START should prevent the countdown from starting,
   * until another script restarts it, or cancelling NOTE_HIT should cause the note to be missed.
   */
  public var cancelable(default, null):Bool;

  /**
   * The type associated with the event.
   */
  public var type(default, null):ScriptEventType;

  /**
   * Whether the event should continue to be triggered on additional targets.
   */
  public var shouldPropagate(default, null):Bool;

  /**
   * Whether the event has been canceled by one of the scripts that received it.
   */
  public var eventCanceled(default, null):Bool;

  public function new(type:ScriptEventType, cancelable:Bool = false):Void
  {
    this.type = type;
    this.cancelable = cancelable;
    this.eventCanceled = false;
    this.shouldPropagate = true;
  }

  /**
   * Call this function on a cancelable event to cancel the associated behavior.
   * For example, cancelling COUNTDOWN_START will prevent the countdown from starting.
   */
  public function cancelEvent():Void
  {
    if (cancelable)
    {
      eventCanceled = true;
    }
  }

  /**
   * Cancel this event.
   * This is an alias for cancelEvent() but I make this typo all the time.
   */
  public function cancel():Void
  {
    cancelEvent();
  }

  /**
   * Call this function to stop any other Scripteds from receiving the event.
   */
  public function stopPropagation():Void
  {
    shouldPropagate = false;
  }

  public function toString():String
  {
    return 'ScriptEvent(type=$type, cancelable=$cancelable)';
  }
}

/**
 * SPECIFIC EVENTS
 */
/**
 * An event that is fired associated with a specific note.
 */
class NoteScriptEvent extends ScriptEvent
{
  /**
   * The note associated with this event.
   * You cannot replace it, but you can edit it.
   */
  public var note(default, null):NoteSprite;

  /**
   * The combo count as it is with this event.
   * Will be (combo) on miss events and (combo + 1) on hit events (the stored combo count won't update if the event is cancelled).
   */
  public var comboCount(default, null):Int;

  /**
   * Whether to play the record scratch sound (if this eventn type is `NOTE_MISS`).
   */
  public var playSound(default, default):Bool;

  public function new(type:ScriptEventType, note:NoteSprite, comboCount:Int = 0, cancelable:Bool = false):Void
  {
    super(type, cancelable);
    this.note = note;
    this.comboCount = comboCount;
    this.playSound = true;
  }

  public override function toString():String
  {
    return 'NoteScriptEvent(type=' + type + ', cancelable=' + cancelable + ', note=' + note + ', comboCount=' + comboCount + ')';
  }
}

/**
 * An event that is fired when you press a key with no note present.
 */
class GhostMissNoteScriptEvent extends ScriptEvent
{
  /**
   * The direction that was mistakenly pressed.
   */
  public var dir(default, null):NoteDirection;

  /**
   * Whether there was a note within judgement range when this ghost note was pressed.
   */
  public var hasPossibleNotes(default, null):Bool;

  /**
   * How much health should be lost when this ghost note is pressed.
   * Remember that max health is 2.00.
   */
  public var healthChange(default, default):Float;

  /**
   * How much score should be lost when this ghost note is pressed.
   */
  public var scoreChange(default, default):Int;

  /**
   * Whether to play the record scratch sound.
   */
  public var playSound(default, default):Bool;

  /**
   * Whether to play the miss animation on the player.
   */
  public var playAnim(default, default):Bool;

  public function new(dir:NoteDirection, hasPossibleNotes:Bool, healthChange:Float, scoreChange:Int):Void
  {
    super(ScriptEventType.NOTE_GHOST_MISS, true);
    this.dir = dir;
    this.hasPossibleNotes = hasPossibleNotes;
    this.healthChange = healthChange;
    this.scoreChange = scoreChange;
    this.playSound = true;
    this.playAnim = true;
  }

  public override function toString():String
  {
    return 'GhostMissNoteScriptEvent(dir=' + dir + ', hasPossibleNotes=' + hasPossibleNotes + ')';
  }
}

/**
 * An event that is fired when the song reaches an event.
 */
class SongEventScriptEvent extends ScriptEvent
{
  /**
   * The note associated with this event.
   * You cannot replace it, but you can edit it.
   */
  public var event(default, null):funkin.data.song.SongData.SongEventData;

  public function new(event:funkin.data.song.SongData.SongEventData):Void
  {
    super(ScriptEventType.SONG_EVENT, true);
    this.event = event;
  }

  public override function toString():String
  {
    return 'SongEventScriptEvent(event=' + event + ')';
  }
}

/**
 * An event that is fired during the update loop.
 */
class UpdateScriptEvent extends ScriptEvent
{
  /**
   * The note associated with this event.
   * You cannot replace it, but you can edit it.
   */
  public var elapsed(default, null):Float;

  public function new(elapsed:Float):Void
  {
    super(ScriptEventType.UPDATE, false);
    this.elapsed = elapsed;
  }

  public override function toString():String
  {
    return 'UpdateScriptEvent(elapsed=$elapsed)';
  }
}

/**
 * An event that is fired regularly during the song.
 * May be on beat or on step.
 */
class SongTimeScriptEvent extends ScriptEvent
{
  /**
   * The current beat of the song.
   */
  public var beat(default, null):Int;

  /**
   * The current step of the song.
   */
  public var step(default, null):Int;

  public function new(type:ScriptEventType, beat:Int, step:Int):Void
  {
    super(type, true);
    this.beat = beat;
    this.step = step;
  }

  public override function toString():String
  {
    return 'SongTimeScriptEvent(type=' + type + ', beat=' + beat + ', step=' + step + ')';
  }
}

/**
 * An event that is fired regularly during the song.
 * May be on beat or on step.
 */
class CountdownScriptEvent extends ScriptEvent
{
  /**
   * The current step of the countdown.
   */
  public var step(default, null):CountdownStep;

  public function new(type:ScriptEventType, step:CountdownStep, cancelable:Bool = true):Void
  {
    super(type, cancelable);
    this.step = step;
  }

  public override function toString():String
  {
    return 'CountdownScriptEvent(type=' + type + ', step=' + step + ')';
  }
}

/**
 * An event that is fired during a dialogue.
 */
class DialogueScriptEvent extends ScriptEvent
{
  /**
   * The dialogue being referenced by the event.
   */
  public var conversation(default, null):Conversation;

  public function new(type:ScriptEventType, conversation:Conversation, cancelable:Bool = true):Void
  {
    super(type, cancelable);
    this.conversation = conversation;
  }

  public override function toString():String
  {
    return 'DialogueScriptEvent(type=$type, conversation=$conversation)';
  }
}

/**
 * An event that is fired when the player presses a key.
 */
class KeyboardInputScriptEvent extends ScriptEvent
{
  /**
   * The associated keyboard event.
   */
  public var event(default, null):KeyboardEvent;

  public function new(type:ScriptEventType, event:KeyboardEvent):Void
  {
    super(type, false);
    this.event = event;
  }

  public override function toString():String
  {
    return 'KeyboardInputScriptEvent(type=' + type + ', event=' + event + ')';
  }
}

/**
 * An event that is fired once the song's chart has been parsed.
 */
class SongLoadScriptEvent extends ScriptEvent
{
  /**
   * The note associated with this event.
   * You cannot replace it, but you can edit it.
   */
  public var notes(default, set):Array<SongNoteData>;

  public var id(default, null):String;

  public var difficulty(default, null):String;

  function set_notes(notes:Array<SongNoteData>):Array<SongNoteData>
  {
    this.notes = notes;
    return this.notes;
  }

  public function new(id:String, difficulty:String, notes:Array<SongNoteData>):Void
  {
    super(ScriptEventType.SONG_LOADED, false);
    this.id = id;
    this.difficulty = difficulty;
    this.notes = notes;
  }

  public override function toString():String
  {
    var noteStr = notes == null ? 'null' : 'Array(' + notes.length + ')';
    return 'SongLoadScriptEvent(notes=$noteStr, id=$id, difficulty=$difficulty)';
  }
}

/**
 * An event that is fired when moving out of or into an FlxState.
 */
class StateChangeScriptEvent extends ScriptEvent
{
  /**
   * The state the game is moving into.
   */
  public var targetState(default, null):FlxState;

  public function new(type:ScriptEventType, targetState:FlxState, cancelable:Bool = false):Void
  {
    super(type, cancelable);
    this.targetState = targetState;
  }

  public override function toString():String
  {
    return 'StateChangeScriptEvent(type=' + type + ', targetState=' + targetState + ')';
  }
}

/**
 * An event that is fired when moving out of or into an FlxSubState.
 */
class SubStateScriptEvent extends ScriptEvent
{
  /**
   * The state the game is moving into.
   */
  public var targetState(default, null):FlxSubState;

  public function new(type:ScriptEventType, targetState:FlxSubState, cancelable:Bool = false):Void
  {
    super(type, cancelable);
    this.targetState = targetState;
  }

  public override function toString():String
  {
    return 'SubStateScriptEvent(type=' + type + ', targetState=' + targetState + ')';
  }
}

/**
 * An event which is called when the player attempts to pause the game.
 */
class PauseScriptEvent extends ScriptEvent
{
  /**
   * Whether to use the Gitaroo Man pause.
   */
  public var gitaroo(default, default):Bool;

  public function new(gitaroo:Bool):Void
  {
    super(ScriptEventType.PAUSE, true);
    this.gitaroo = gitaroo;
  }
}
