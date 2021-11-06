package;

import haxe.Exception;
import openfl.geom.Matrix;
import openfl.display.BitmapData;
import flixel.system.FlxSound;
import flixel.util.FlxAxes;
import flixel.FlxSubState;
import Options.Option;
import flixel.input.FlxInput;
import flixel.input.keyboard.FlxKey;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.effects.FlxFlicker;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import lime.app.Application;
import lime.utils.Assets;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.input.FlxKeyManager;
import flixel.FlxCamera;

using StringTools;

class ResultsScreen extends MusicBeatSubstate
{
    public var text:FlxText;

    public var staticvine:FlxSprite;

    public var comboText:FlxText;
    public var contText:FlxText;
    public var settingsText:FlxText;

    public var music:FlxSound;

    public var graphData:BitmapData;

    public var ranking:String;
    public var accuracy:String;

	override function create()
	{
		if (PlayState.Stage.curStage == "zardyBruh")
            {
                var video = new VideoPlayer(0,0, "assets/videos/vineShit.webm");
                video.finishCallback = () -> {
                	staticvine.visible = true;
                }
				video.ownCamera();
				video.setGraphicSize(FlxG.width);
		        video.updateHitbox();
				add(video);
				video.play();

                staticvine = new FlxSprite(video.x,video.y).loadGraphic(Paths.image("five-minute-song/Staticvine", "ChallengeWeek"));
                staticvine.scrollFactor.set();
                staticvine.antialiasing = true;
                //staticvine.setGraphicSize(FlxG.width);
                staticvine.width = video.width;
                staticvine.height = video.height;
                staticvine.visible = false;
                add(staticvine);
            }

        if (!PlayState.inResults) 
        {
            music = new FlxSound().loadEmbedded(Paths.music('breakfast'), true, true);
            music.volume = 0;
            music.play(false, FlxG.random.int(0, Std.int(music.length / 2)));
            FlxG.sound.list.add(music);
        }

        text = new FlxText(20,-55,0,"Song Cleared!");
        text.size = 34;
        text.setBorderStyle(FlxTextBorderStyle.OUTLINE,FlxColor.BLACK,4,1);
        text.color = FlxColor.WHITE;
        text.scrollFactor.set();
        add(text);

        var score = PlayState.instance.songScore;
        if (PlayState.isStoryMode)
        {
            score = PlayState.campaignScore;
            text.text = "Week Cleared!";
        }

        comboText = new FlxText(20,-75,0,'Judgements:\nSicks - ${PlayState.sicks}\nGoods - ${PlayState.goods}\nBads - ${PlayState.bads}\n\nCombo Breaks: ${(PlayState.isStoryMode ? PlayState.campaignMisses : PlayState.misses)}\nHighest Combo: ${PlayState.highestCombo + 1}\nScore: ${PlayState.instance.songScore}\nAccuracy: ${HelperFunctions.truncateFloat(PlayState.instance.accuracy,2)}%\n\n${Ratings.GenerateLetterRank(PlayState.instance.accuracy)}\n\nBack - Replay song
        ');
        comboText.size = 28;
        comboText.setBorderStyle(FlxTextBorderStyle.OUTLINE,FlxColor.BLACK,4,1);
        comboText.color = FlxColor.WHITE;
        comboText.scrollFactor.set();
        add(comboText);

        contText = new FlxText(FlxG.width - 475,FlxG.height + 50,0,'Press ENTER to continue.');
        contText.size = 28;
        contText.setBorderStyle(FlxTextBorderStyle.OUTLINE,FlxColor.BLACK,4,1);
        contText.color = FlxColor.WHITE;
        contText.scrollFactor.set();
        add(contText);

        var sicks = HelperFunctions.truncateFloat(PlayState.sicks / PlayState.goods,1);
        var goods = HelperFunctions.truncateFloat(PlayState.goods / PlayState.bads,1);

        if (sicks == Math.POSITIVE_INFINITY)
            sicks = 0;
        if (goods == Math.POSITIVE_INFINITY)
            goods = 0;

        settingsText = new FlxText(20,FlxG.height + 50,0,'Ratio (SA/GA): ${Math.round(sicks)}:1 ${Math.round(goods)}:1 | Played on ${PlayState.SONG.song} ${CoolUtil.difficultyFromInt(PlayState.storyDifficulty).toUpperCase()}');
        settingsText.size = 16;
        settingsText.setBorderStyle(FlxTextBorderStyle.OUTLINE,FlxColor.BLACK,2,1);
        settingsText.color = FlxColor.WHITE;
        settingsText.scrollFactor.set();
        add(settingsText);

        FlxTween.tween(text, {y:20},0.5,{ease: FlxEase.expoInOut});
        FlxTween.tween(comboText, {y:145},0.5,{ease: FlxEase.expoInOut});
        FlxTween.tween(contText, {y:FlxG.height - 45},0.5,{ease: FlxEase.expoInOut});
        FlxTween.tween(settingsText, {y:FlxG.height - 35},0.5,{ease: FlxEase.expoInOut});

        cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];

        #if mobileC
        addVirtualPad(NONE, A_B);
        
        var camcontrol = new FlxCamera();
        FlxG.cameras.add(camcontrol);
        camcontrol.bgColor.alpha = 0;
        _virtualpad.cameras = [camcontrol];
        #end

		super.create();
	}


    var frames = 0;

	override function update(elapsed:Float)
	{
        if (music != null && music.volume < 0.5)
		    music.volume += 0.01 * elapsed;

        if (controls.ACCEPT)
        {
            music.fadeOut(0.3);

            if (PlayState.isStoryMode)
            {
                FlxG.sound.playMusic(Paths.music('freakyMenu'));
                Conductor.changeBPM(102);
                PlayState.instance.useVideo = false;
                FlxG.switchState(new MainMenuState());
            }
            else
                PlayState.instance.useVideo = false;
                FlxG.switchState(new FreeplayState());
        }

        if (controls.BACK)
        {
            var songFormat = StringTools.replace(PlayState.SONG.song, " ", "-");

            var poop:String = Highscore.formatSong(songFormat, PlayState.storyDifficulty);

            if (music != null)
                music.fadeOut(0.3);

            PlayState.SONG = Song.loadFromJson(poop, PlayState.SONG.song);
            PlayState.isStoryMode = false;
            PlayState.storyDifficulty = PlayState.storyDifficulty;
            PlayState.instance.useVideo = false;
            LoadingState.loadAndSwitchState(new PlayState());
        }

		super.update(elapsed);
		
	}
}
