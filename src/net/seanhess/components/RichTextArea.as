package net.seanhess.components
{                                 
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;  
	import flash.text.TextFormat;
	import flash.text.TextField;
	
	import mx.controls.TextArea;
	import mx.controls.textClasses.TextRange; 
	import mx.core.UITextFormat;
	import mx.core.UITextField;
	import mx.core.IUITextField;
	                             
	[Event("mouseUpNewCaret")]  
	[Event("selectionChange")]  
	[DefaultTriggerEvent("change")]
	public class RichTextArea extends TextArea
	{                                
		public static const SELECTION_CHANGE:String = "selectionChange";
		
		[Bindable] public var format:TextFormat = null;
		protected var previousTextFormat:TextFormat = null;
		protected var lastCaretIndex:int = -1;   

		private var firstTime:Boolean = true;
		private var textFormatChanged:Boolean = false;   
		private var htmlTextChanged:Boolean = false;
		private var textChanged:Boolean = false;
		
		public function RichTextArea()
		{
			minHeight = 0;
			minWidth = 0;
			addEventListener(KeyboardEvent.KEY_DOWN , onKeyDown);
			addEventListener(MouseEvent.MOUSE_DOWN , onMouseDown);
		}           
		
		public function getTextField():IUITextField
		{
			return textField;
		}             
		
		public function hasFormatChanged(key:String):Boolean
		{
			return (!previousTextFormat || previousTextFormat[key] != format[key])
		}
		
		public function getFormat(key:String):*
		{
			return format[key];
		}
		
		public function setFormat(type:String, value:Object = null):void
		{
			setTextStyles(type, value);
		}
		
		
		
		
		
	    //----------------------------------
	    //  selection
	    //----------------------------------

		/**
	     *  The selected text.
	     */
		public function get selection():TextRange
		{
			return new TextRange(this, true);
		}		
		
		           
		//----------------------------------
	    //  text
	    //----------------------------------
	
		private var formatDirty:Boolean = false;

		[Bindable("valueCommit")]
		[CollapseWhiteSpace]
		[NonCommittingChangeEvent("change")]
		[Inspectable(category="General")]

		override public function get text():String
		{
			return super.text;
		}

		override public function set text(value:String):void
		{
			super.text = value;
			formatDirty = true;
			invalidateProperties();
		}
  

		
	    //----------------------------------
	    //  htmlText
	    //----------------------------------

		[Bindable("valueCommit")]
		[CollapseWhiteSpace]
		[NonCommittingChangeEvent("change")]
		[Inspectable(category="General")]

		override public function get htmlText():String
		{
			return super.htmlText;
		}

		override public function set htmlText(value:String):void
		{
			super.htmlText = value;
			formatDirty = true;
			invalidateProperties();
		}		    
		
		/**
		*	Returns the TextFormat for the currently selected text
		*/
		public function get selectedTextFormat():TextFormat
		{
			var beginIndex:int = getTextField().selectionBeginIndex;
			var endIndex:int = getTextField().selectionEndIndex;

			return getSelectionTextFormat(beginIndex, endIndex);   
		}
		
		override protected function commitProperties():void
		{
			super.commitProperties();

			if (firstTime)
			{
				firstTime = false;
				getTextField().alwaysShowSelection = true;
			}

			if (formatDirty)
			{
				// Revert previously set TextFormat.
				var tf:UITextFormat = IUITextField(getTextField()).getUITextFormat();
				// bullet style is not exposed in flex
				// hence has to be explicitly defaulted.
				tf.bullet = false;
				getTextField().defaultTextFormat = tf;
				formatDirty = false;
			}
		}
		
		// SET TEXT STYLES // 
		protected function setTextStyles(type:String, value:Object = null):void
		{                  
			var beginIndex:int 	= getTextField().selectionBeginIndex;
			var endIndex:int 	= getTextField().selectionEndIndex;

			var tf:TextFormat = initializeTextFormat(type, beginIndex, endIndex);  
			
			tf = prepareTextFormat(tf, type, value);

			textFormatChanged = true;

			if (beginIndex == endIndex)
			{
				previousTextFormat = tf;
			}
			else
			{
				getTextField().setTextFormat(tf,beginIndex,endIndex);
			}

			dispatchEvent(new Event("change"));
			fixFocus();
		}      
		
		protected function initializeTextFormat(type:String, beginIndex:int, endIndex:int):TextFormat
		{       
			if (beginIndex == endIndex)
				return previousTextFormat; 
				
			else	
				return new TextFormat(); 
		}
		
		protected function prepareTextFormat(tf:TextFormat, type:String, value:Object = null):TextFormat
		{      
			if (type == "url")
			{
				tf.target = (value != "") ? "_blank" : "";
				tf = (value != "") ? addDefaultLinkFormatting(tf) : removeDefaultLinkFormatting(tf);
			}
			   
			if (tf)
				tf[type] = value;
				
			return tf;
		}
		
		protected function addDefaultLinkFormatting(tf:TextFormat):TextFormat
		{
			tf.underline = true;
			tf.color = 0x0000FF;
			
			return tf;
		}
		
		protected function removeDefaultLinkFormatting(tf:TextFormat):TextFormat
		{
			tf.underline = false;
			tf.color = 0x000000;
			
			return tf;
		}
              
		protected function fixFocus():void
		{
			var caretIndex:int = getTextField().caretIndex;
			var lineIndex:int =	getTextField().getLineIndexOfChar(caretIndex);

			invalidateDisplayList();
			validateDisplayList();

			// Scroll to make the line containing the caret under viewable area
			while (lineIndex >= getTextField().bottomScrollV)
			{
				verticalScrollPosition++;
			}

			callLater(setFocus);			
		}
           


		// GET TEXT STYLES // 
		protected function getTextStyles():void
		{
			var beginIndex:int = getTextField().selectionBeginIndex;
			var endIndex:int = getTextField().selectionEndIndex;

			if (textFormatChanged)
				previousTextFormat = null;    
				
			format = getSelectionTextFormat(beginIndex, endIndex);   

			updateFormatting(previousTextFormat, format);

			previousTextFormat = format;
			textFormatChanged = false;  
			
			finishGetTextStyles();
		}                      
		
		protected function finishGetTextStyles():void
		{
			lastCaretIndex = getTextField().caretIndex;
		}
		
		public function getSelectionTextFormat(beginIndex:int, endIndex:int):TextFormat
		{
			if (beginIndex == endIndex)
			{             
				return getPointTextFormat();
			}
			else
				return getRangeTextFormat(beginIndex, endIndex);
		}                                                       
		
		protected function getRangeTextFormat(beginIndex:int, endIndex:int):TextFormat
		{
			return getTextField().getTextFormat(beginIndex,endIndex);
		}
		
		protected function getPointTextFormat():TextFormat
		{
			var tf:TextFormat = getTextField().defaultTextFormat;
			
			var carIndex:int = getTextField().caretIndex;
			if (carIndex < getTextField().length)
			{
				var tfNext:TextFormat=getTextField().getTextFormat(carIndex, carIndex + 1);
				if (!tfNext.url || tfNext.url == "")
					tf.url = tf.target = "";
			}
			else
				tf.url = tf.target = "";  
				
		    return tf;
		}               
            
		protected function updateFormatting(previousTextFormat:TextFormat, tf:TextFormat):void
		{                      
			dispatchEvent(new Event(SELECTION_CHANGE));
		}



		
		
		// OVERRIDEABLE //
		protected function resetTextFormat():void
		{
			if (textFormatChanged) 
			{
				getTextField().defaultTextFormat=previousTextFormat;
				textFormatChanged = false;
			}
		}		
		


		
		
		// EVENTS //
		private function onKeyDown(event:Event):void
		{        
			resetTextFormat();
		} 

		private function onMouseDown(event:Event):void
		{
			systemManager.addEventListener(MouseEvent.MOUSE_UP, systemManager_mouseUpHandler, true);				
		}     

		private function systemManager_mouseUpHandler(event:MouseEvent):void
		{
			if (lastCaretIndex != getTextField().caretIndex)
				getTextStyles();   

			else
				dispatchEvent(new Event('mouseUpNewCaret'))

			systemManager.removeEventListener(MouseEvent.MOUSE_UP, systemManager_mouseUpHandler, true);		
		}     
	  	
	}
	
	
}
		   
