--[[
	Base SGUI control. All controls inherit from this.
]]

local CodeGen = require "shine/lib/codegen"

local SGUI = Shine.GUI
local ControlMeta = SGUI.BaseControl
local Set = Shine.Set

local assert = assert
local Clock = SGUI.GetTime
local IsType = Shine.IsType
local IsGUIItemValid = debug.isvalid
local Max = math.max
local pairs = pairs
local select = select
local StringFormat = string.format
local TableNew = require "table.new"
local TableRemoveByValue = table.RemoveByValue
local Vector2 = Vector2
local Vector = Vector

local Map = Shine.Map
local Multimap = Shine.Multimap
local Source = require "shine/lib/gui/binding/source"
local UnorderedMap = Shine.UnorderedMap

local SetterKeys = SGUI.SetterKeys

SGUI.AddBoundProperty( ControlMeta, "BlendTechnique", "Background" )
SGUI.AddBoundProperty( ControlMeta, "InheritsParentAlpha", {
	"Background",
	function( self, InheritsParentAlpha )
		if self.GUIItems then
			for Item in self.GUIItems:Iterate() do
				Item:SetInheritsParentAlpha( InheritsParentAlpha )
			end
		end
	end
} )
SGUI.AddBoundProperty( ControlMeta, "InheritsParentScaling", {
	"Background",
	function( self, InheritsParentScaling )
		if self.GUIItems then
			for Item in self.GUIItems:Iterate() do
				Item:SetInheritsParentScaling( InheritsParentScaling )
			end
		end
	end
} )
SGUI.AddBoundProperty( ControlMeta, "Scale", "Background" )
SGUI.AddBoundProperty( ControlMeta, "Shader", "Background" )
SGUI.AddBoundProperty( ControlMeta, "Texture", "Background" )

SGUI.AddProperty( ControlMeta, "AlphaMultiplier", 1 )
SGUI.AddProperty( ControlMeta, "CroppingBounds" )
SGUI.AddProperty( ControlMeta, "DebugName", "Unnamed" )
SGUI.AddProperty( ControlMeta, "PropagateAlphaInheritance", false )
SGUI.AddProperty( ControlMeta, "PropagateScaleInheritance", false )
SGUI.AddProperty( ControlMeta, "PropagateSkin", true )
SGUI.AddProperty( ControlMeta, "Skin" )
SGUI.AddProperty( ControlMeta, "StyleName" )
SGUI.AddProperty( ControlMeta, "TargetAlpha", 1 )

function ControlMeta:__tostring()
	local NumChildren = self.Children and self.Children:GetCount() or 0
	return StringFormat(
		"[SGUI - %s: %s] %s | %s | %i Child%s",
		self.ID,
		self:GetDebugName(),
		self.Class,
		self:IsValid() and "ACTIVE" or "DESTROYED",
		NumChildren,
		NumChildren == 1 and "" or "ren"
	)
end

--[[
	Base initialise. Be sure to override this!
]]
function ControlMeta:Initialise()
	self.UseScheme = true
	self.InheritsParentAlpha = false
	self.PropagateAlphaInheritance = false
	self.InheritsParentScaling = false
	self.PropagateScaleInheritance = false
	self.PropagateSkin = true
	self.Stencilled = false

	self.MouseHasEntered = false
	self.MouseStateIsInvalid = false

	self.ApplyCalculatedAlphaToColour = self.ApplyCalculatedAlphaToColourWithoutAlphaModifier
	self.CalculateAlpha = self.CalculateAlphaWithoutMultiplierOrInheritance
end

--[[
	Generic cleanup, for most controls this is adequate.

	The only time you need to override it is if you have more than a background object.
]]
function ControlMeta:Cleanup()
	if SGUI.IsValid( self.Tooltip ) then
		self.Tooltip:Destroy()
		self.Tooltip = nil
	end

	if self.Parent then return end

	if self.GUIItems then
		local FoundBackground = false
		local TopLevelElements = {}
		for Item in self.GUIItems:Iterate() do
			if Item == self.Background then
				FoundBackground = true
			end

			-- Destroy all GUIItems that are not parented to another element
			-- in this element's GUIItem children.
			if IsGUIItemValid( Item ) and not self.GUIItems:Get( Item:GetParent() ) then
				TopLevelElements[ #TopLevelElements + 1 ] = Item
			end
		end

		for i = 1, #TopLevelElements do
			GUI.DestroyItem( TopLevelElements[ i ] )
		end

		-- If the background element was removed above, then stop.
		if FoundBackground then return end
	end

	-- This retains backwards compatibility, in case anyone made custom SGUI controls
	-- before Control:MakeGUIItem() existed.
	if self.Background then
		GUI.DestroyItem( self.Background )
	end
end

--[[
	Destroys a control.
]]
function ControlMeta:Destroy()
	return SGUI:Destroy( self )
end

--[[
	Sets a control to be destroyed when this one is.
]]
function ControlMeta:DeleteOnRemove( Control )
	self.__DeleteOnRemove = self.__DeleteOnRemove or {}

	local Table = self.__DeleteOnRemove

	Table[ #Table + 1 ] = Control
end

--[[
	Stops a control being destroyed when this one is.
]]
function ControlMeta:ResetDeleteOnRemove( Control )
	if not self.__DeleteOnRemove then return end

	TableRemoveByValue( self.__DeleteOnRemove, Control )
end

--[[
	Adds a function to be called when this control is destroyed.

	It will be passed this control when called as its argument.
]]
function ControlMeta:CallOnRemove( Func )
	self.__CallOnRemove = self.__CallOnRemove or {}

	local Table = self.__CallOnRemove

	Table[ #Table + 1 ] = Func
end

function ControlMeta:OnPropertyChanged( Name, Value )
	-- By default, do nothing until a listener is added.
end

local function BroadcastPropertyChange( self, Name, Value )
	local Listeners = self.PropertyChangeListeners:Get( Name )
	if not Listeners then return end

	for i = #Listeners, 1, -1 do
		Listeners[ i ]( self, Value )
	end
end

function ControlMeta:AddPropertyChangeListener( Name, Listener )
	-- Now listening for changes, so need to broadcast them.
	self.OnPropertyChanged = BroadcastPropertyChange

	self.PropertyChangeListeners = self.PropertyChangeListeners or Multimap()
	self.PropertyChangeListeners:Add( Name, Listener )

	return Listener
end

function ControlMeta:GetPropertySource( Name )
	self.PropertySources = self.PropertySources or {}

	local SourceInstance = self.PropertySources[ Name ]
	if SourceInstance then
		return SourceInstance
	end

	local Getter = self[ "Get"..Name ]
	local Value
	if Getter then
		Value = Getter( self )
	else
		Value = self[ Name ]
	end

	SourceInstance = Source( Value )
	SourceInstance.Element = self

	self.PropertySources[ Name ] = SourceInstance
	self:AddPropertyChangeListener( Name, SourceInstance )

	return SourceInstance
end

function ControlMeta:GetPropertyTarget( Name )
	self.PropertyTargets = self.PropertyTargets or {}

	local Target = self.PropertyTargets[ Name ]
	if Target then
		return Target
	end

	local SetterName = SetterKeys[ Name ]
	Target = function( ... )
		return self[ SetterName ]( self, ... )
	end

	self.PropertyTargets[ Name ] = Target

	return Target
end

function ControlMeta:RemovePropertyChangeListener( Name, Listener )
	local Listeners = self.PropertyChangeListeners
	if not Listeners then return end

	Listeners:Remove( Name, Listener )

	if Listeners:GetCount() == 0 then
		-- No more listeners, stop adding overhead.
		self.PropertyChangeListeners = nil
		self.OnPropertyChanged = ControlMeta.OnPropertyChanged
	end
end

-- Deprecated single state setter. Use AddStylingState(s)/RemoveStylingState(s) to allow for multiple states.
function ControlMeta:SetStylingState( Name )
	if Name then
		self:GetStylingStates():Clear():Add( Name )
	else
		self.StylingStates = nil
		self.GetStylingStates = ControlMeta.GetStylingStates
	end

	self:RefreshStyling()
end

function ControlMeta:AddStylingState( Name )
	local States = self:GetStylingStates()
	if not States:Contains( Name ) then
		States:Add( Name )
		self:RefreshStyling()
	end
end

function ControlMeta:AddStylingStates( Names )
	local States = self:GetStylingStates()
	local PreviousCount = States:GetCount()

	States:AddAll( Names )

	if States:GetCount() > PreviousCount then
		self:RefreshStyling()
	end
end

function ControlMeta:RemoveStylingState( Name )
	local States = self.StylingStates
	if States and States:Contains( Name ) then
		States:Remove( Name )
		self:RefreshStyling()
	end
end

function ControlMeta:RemoveStylingStates( Names )
	local States = self.StylingStates
	if not States then return end

	local PreviousCount = States:GetCount()

	States:RemoveAll( Names )

	if States:GetCount() < PreviousCount then
		self:RefreshStyling()
	end
end

function ControlMeta:SetStylingStateActive( Name, Active )
	if Active then
		self:AddStylingState( Name )
	else
		self:RemoveStylingState( Name )
	end
end

-- Deprecated single-style state accessor. Controls may have more than one active state.
function ControlMeta:GetStylingState()
	return self.StylingStates and self.StylingStates:AsList()[ 1 ]
end

do
	local function GetStylingStatesUnsafe( self )
		return self.StylingStates
	end

	function ControlMeta:GetStylingStates()
		if not self.StylingStates then
			self.StylingStates = Set()
			self.GetStylingStates = GetStylingStatesUnsafe
		end

		return self.StylingStates
	end
end

--[[
	Sets the style name for the given control.

	This can be either a string to use a single style name, or an array of names. When specifying multiple style names,
	properties from latter names override the values from those before and the default style.
]]
function ControlMeta:SetStyleName( Name )
	if self.StyleName == Name then return end

	self.StyleName = Name
	self:RefreshStyling()
end

function ControlMeta:RefreshStyling()
	SGUI.SkinManager:ApplySkin( self )
end

function ControlMeta:SetSkin( Skin )
	local OldSkin = self.Skin
	if OldSkin == Skin then return end

	if Skin then
		-- Trigger skin compilation upfront to make later state changes faster.
		SGUI.SkinManager:GetCompiledSkin( Skin )
	end

	self.Skin = Skin
	self:RefreshStyling()

	self:OnPropertyChanged( "Skin", Skin )

	if self.PropagateSkin and self.Children then
		for Child in self:IterateChildren() do
			Child:SetSkin( Skin )
		end
	end
end

function ControlMeta:GetStyleValue( Key )
	local Style = SGUI.SkinManager:GetStyleForElement( self )
	if not Style then
		return nil
	end
	return Style.PropertiesByName[ Key ]
end

--[[
	Sets up a control's properties using a table.
]]
function ControlMeta:SetupFromTable( Table )
	for Property, Value in pairs( Table ) do
		local Method = self[ SetterKeys[ Property ] ]
		if Method then
			Method( self, Value )
		end
	end
end

--[[
	Sets up a control's properties using a map.
]]
function ControlMeta:SetupFromMap( Map )
	for Property, Value in Map:Iterate() do
		local Method = self[ SetterKeys[ Property ] ]
		if Method then
			Method( self, Value )
		end
	end
end

do
	local TableShallowMerge = table.ShallowMerge

	--[[
		Use to more easily setup multiple callback methods.
	]]
	function ControlMeta:AddMethods( Methods )
		TableShallowMerge( Methods, self, true )
	end
end

--[[
	Sets a control's parent manually.
]]
function ControlMeta:SetParent( Control, Element )
	assert( Control ~= self, "[SGUI] Cannot parent an object to itself!" )

	if Control and not Element then
		Element = Control.Background
	end

	local ParentControlChanged = self.Parent ~= Control
	local ParentElementChanged = self.ParentElement ~= Element

	if not ParentControlChanged and not ParentElementChanged then
		return
	end

	if ParentControlChanged and self.Parent then
		self.Parent.Children:Remove( self )
		self.Parent.ChildrenByPositionType:RemoveKeyValue( self:GetPositionType(), self )
	end

	if ParentElementChanged and self.ParentElement and IsGUIItemValid( self.ParentElement ) and self.Background then
		self.ParentElement:RemoveChild( self.Background )
	end

	self:InvalidateMouseState()

	if not Control then
		self.Parent = nil
		self.ParentElement = nil
		self.TopLevelWindow = nil
		self:SetStencilled( false )
		self:InvalidateCroppingState()
		return
	end

	-- Parent to a specific part of a control.
	self.Parent = Control
	self.ParentElement = Element
	self:SetTopLevelWindow( SGUI:IsWindow( Control ) and Control or Control.TopLevelWindow )
	self:SetStencilled( Control.Stencilled )
	if Control.Stencilled then
		self:SetInheritsParentStencilSettings( true )
	end

	if Control.PropagateAlphaInheritance then
		self:SetInheritsParentAlpha( Control:GetInheritsParentAlpha() )
		self:SetPropagateAlphaInheritance( true )
	end

	if Control.PropagateScaleInheritance then
		self:SetInheritsParentScaling( Control:GetInheritsParentScaling() )
		self:SetPropagateScaleInheritance( true )
	end

	if Control.PropagateSkin then
		self:SetSkin( Control.Skin )
	end

	-- If the control was a window, now it's not.
	self.IsAWindow = false
	SGUI:RemoveWindow( self )

	Control.Children = Control.Children or Map()
	Control.Children:Add( self, true )

	Control.ChildrenByPositionType = Control.ChildrenByPositionType or Multimap()
	Control.ChildrenByPositionType:Add( self:GetPositionType(), self )

	if ParentElementChanged and Element and self.Background then
		Element:AddChild( self.Background )
	end

	self:InvalidateCroppingState()
end

function ControlMeta:SetTopLevelWindow( Window )
	if Window == self.TopLevelWindow then return end

	self.TopLevelWindow = Window

	if Window and self.Children then
		for Child in self.Children:Iterate() do
			Child:SetTopLevelWindow( Window )
		end
	end

	self:OnPropertyChanged( "TopLevelWindow", Window )
end

do
	local Callers = CodeGen.MakeFunctionGenerator( {
		Template = [[return function( self, Name{Arguments} )
				if not self.Children then return nil end

				-- Call the event on every child of this object in the order they were added.
				for Child in self.Children:Iterate() do
					if Child[ Name ] and not Child._CallEventsManually then
						local Result, Control = Child[ Name ]( Child{Arguments} )

						if Result ~= nil then
							return Result, Control
						end
					end
				end

				return nil
			end
		]],
		ChunkName = "@lua/shine/lib/gui/base_control.lua/ControlMeta:CallOnChildren",
		InitialSize = 2
	} )

	--[[
		Calls an SGUI event on every child of the object.

		Ignores children with the _CallEventsManually flag.
	]]
	function ControlMeta:CallOnChildren( Name, ... )
		return Callers[ select( "#", ... ) ]( self, Name, ... )
	end
end

function ControlMeta:ForEach( TableKey, MethodName, ... )
	local Objects = self[ TableKey ]
	if not Objects then return end

	for i = 1, #Objects do
		local Object = Objects[ i ]
		local Method = Object[ MethodName ]
		if Method then
			Method( Object, ... )
		end
	end
end

function ControlMeta:ForEachFiltered( TableKey, MethodName, Filter, ... )
	local Objects = self[ TableKey ]
	if not Objects then return end

	for i = 1, #Objects do
		local Object = Objects[ i ]
		local Method = Object[ MethodName ]
		if Method and Filter( self, Object, i ) then
			Method( Object, ... )
		end
	end
end

--[[
	Add a GUIItem as a child.
]]
function ControlMeta:AddChild( GUIItem )
	self.Background:AddChild( GUIItem )
end

local GUIItemTypes = {
	[ SGUI.GUIItemType.Text ] = SGUI.CreateTextGUIItem,
	[ SGUI.GUIItemType.Graphic ] = SGUI.CreateGUIItem
}

function ControlMeta:MakeGUIItem( Type )
	local Factory = GUIItemTypes[ Type or SGUI.GUIItemType.Graphic ]
	if not Factory then
		error( "Unknown GUIItem type: "..Type, 2 )
	end

	local Item = Factory()
	Item:SetOptionFlag( GUIItem.CorrectScaling )
	Item:SetOptionFlag( GUIItem.CorrectRotationOffset )
	if self.Stencilled then
		-- This element is currently under the effect of a stencil, so inherit settings.
		Item:SetInheritsParentStencilSettings( true )
	end
	if self.InheritsParentAlpha then
		Item:SetInheritsParentAlpha( true )
	end
	if self.InheritsParentScaling then
		Item:SetInheritsParentScaling( true )
	end

	self.GUIItems = self.GUIItems or Shine.Map()
	self.GUIItems:Add( Item, true )

	return Item
end

function ControlMeta:MakeGUITextItem()
	return self:MakeGUIItem( SGUI.GUIItemType.Text )
end

function ControlMeta:MakeGUICroppingItem()
	local CroppingBox = self:MakeGUIItem()
	CroppingBox:SetMinCrop( 0, 0 )
	CroppingBox:SetMaxCrop( 1, 1 )
	return CroppingBox
end

function ControlMeta:DestroyGUIItem( Item )
	GUI.DestroyItem( Item )

	if self.GUIItems then
		self.GUIItems:Remove( Item )
	end
end

function ControlMeta:SetLayer( Layer )
	self.Background:SetLayer( Layer )
end

function ControlMeta:GetLayer()
	return self.Background:GetLayer()
end

local function IsDescendantOf( Child, Ancestor )
	local Parent = Child:GetParent()
	while Parent and Parent ~= Ancestor do
		Parent = Parent:GetParent()
	end
	return Parent == Ancestor
end

function ControlMeta:SetCropToBounds( CropToBounds )
	if CropToBounds then
		self.Background:SetMinCrop( 0, 0 )
		self.Background:SetMaxCrop( 1, 1 )
	else
		self.Background:ClearCropRectangle()
	end
end

function ControlMeta:IsCroppedByParent()
	local IsCropped = self.__IsCroppedByParent

	if IsCropped == nil then
		-- Lazy-evaluate whether the control is actually visible based on the parent's known cropping bounds.
		local ParentCroppingBounds = self.Parent and self.Parent:GetCroppingBounds()
		if ParentCroppingBounds then
			local ParentPos = self.Parent:GetScreenPos()
			local Mins = ParentPos + ParentCroppingBounds[ 1 ]
			local Maxs = ParentPos + ParentCroppingBounds[ 2 ]
			local SelfPos = self:GetScreenPos()
			local Size = self:GetSize()

			-- Simple bounding box check in screen space.
			IsCropped = SelfPos.x + Size.x < Mins.x or
				SelfPos.x > Maxs.x or
				SelfPos.y + Size.y < Mins.y or
				SelfPos.y > Maxs.y
		else
			IsCropped = false
		end

		-- Remember this until the cropping is updated or this control's position changes.
		self.__IsCroppedByParent = IsCropped
		self:OnPropertyChanged( "CroppedByParent", IsCropped )
	end

	return IsCropped
end

function ControlMeta:InvalidateCroppingState()
	-- Forget the cached cropping state, will be re-evaluated on the next call to IsCroppedByParent().
	self.__IsCroppedByParent = nil
end

function ControlMeta:SetCroppingBounds( Mins, Maxs )
	if not Mins then
		if not self.CroppingBounds then return false end

		self.CroppingBounds = nil
	else
		if self.CroppingBounds and Mins == self.CroppingBounds[ 1 ] and Maxs == self.CroppingBounds[ 2 ] then
			return false
		end

		self.CroppingBounds = self.CroppingBounds or {}
		self.CroppingBounds[ 1 ] = Mins
		self.CroppingBounds[ 2 ] = Maxs
	end

	self:OnPropertyChanged( "CroppingBounds", self.CroppingBounds )
	-- Notify all children that they need to re-evaluate their cropping.
	-- Controls that call this method must also ensure they fire this event when their scrolling box moves.
	self:CallOnChildren( "InvalidateCroppingState" )

	return true
end

--[[
	This is called when the element is added as a direct child of another element that
	has a stencil component.

	Direct children need to have a GUIItem.NotEqual stencil function set. Their descendants
	can then inherit this.
]]
function ControlMeta:SetupStencil()
	local Background = self.Background
	Background:SetInheritsParentStencilSettings( false )
	Background:SetStencilFunc( GUIItem.NotEqual )

	if self.GUIItems then
		for Child in self.GUIItems:Iterate() do
			if not IsDescendantOf( Child, Background ) then
				Child:SetInheritsParentStencilSettings( false )
				Child:SetStencilFunc( GUIItem.NotEqual )
			else
				Child:SetInheritsParentStencilSettings( true )
			end
		end
	end

	self:SetStencilled( true )
end

function ControlMeta:SetStencilled( Stencilled )
	if Stencilled == self.Stencilled then return end

	self.Stencilled = Stencilled
	self:OnStencilChanged( Stencilled )
	-- Notify all children of the new stencil state.
	self:PropagateStencilSettings( Stencilled )
end

function ControlMeta:OnStencilChanged( Stencilled )
	if not self.Stencil then return end

	if Stencilled and not ( self.Parent and self.Parent.IgnoreStencilWarnings ) then
		-- Stencils inside stencils currently don't work correctly. They obey only the top-level
		-- stencil, any further restrictions are ignored (and appear to render as if GetIsStencil() == false).
		Print(
			"[SGUI] [Warn] [ %s ] has been placed under another stencil, this will not render correctly!",
			self
		)
	end
end

function ControlMeta:SetInheritsParentStencilSettings( InheritsParentStencil )
	if self.Background then
		self.Background:SetInheritsParentStencilSettings( InheritsParentStencil )
	end

	if self.GUIItems then
		for Item in self.GUIItems:Iterate() do
			Item:SetInheritsParentStencilSettings( InheritsParentStencil )
		end
	end
end

function ControlMeta:PropagateStencilSettings( Stencilled )
	if self.Children then
		for Child in self.Children:Iterate() do
			Child:SetInheritsParentStencilSettings( Stencilled )
			Child:SetStencilled( Stencilled )
		end
	end
end

do
	local SetInheritsParentScaling = ControlMeta.SetInheritsParentScaling
	function ControlMeta:SetInheritsParentScaling( InheritsParentScaling )
		if not SetInheritsParentScaling( self, InheritsParentScaling ) then return false end

		if self.PropagateScaleInheritance and self.Children then
			for Child in self.Children:Iterate() do
				Child:SetInheritsParentScaling( InheritsParentScaling )
			end
		end

		return true
	end

	local SetPropagateScaleInheritance = ControlMeta.SetPropagateScaleInheritance
	function ControlMeta:SetPropagateScaleInheritance( PropagateScaleInheritance )
		if not SetPropagateScaleInheritance( self, PropagateScaleInheritance ) then return false end

		if PropagateScaleInheritance and self.Children then
			local InheritsParentScaling = self:GetInheritsParentScaling()
			for Child in self.Children:Iterate() do
				Child:SetInheritsParentScaling( InheritsParentScaling )
				Child:SetPropagateScaleInheritance( true )
			end
		end

		return true
	end
end
--[[
	Determines if the given control should use the global skin.
]]
function ControlMeta:SetIsSchemed( Bool )
	self.UseScheme = not not Bool
end

--[[
	Called when the control becomes visible/invisible due to either its own visibility state, or an ancestor's
	visibility state.

	Inputs:
		1. Whether the control is now considered visible.
		2. The control whose visibility change caused this update.
]]
function ControlMeta:OnEffectiveVisibilityChanged( IsEffectivelyVisible, UpdatedControl )
	-- To be overridden by controls as required.
end

do
	local function BroadcastVisibilityChange( self, IsEffectivelyVisible, UpdatedControl )
		self:OnEffectiveVisibilityChanged( IsEffectivelyVisible, UpdatedControl )

		if self.Children then
			for Child in self.Children:Iterate() do
				-- Only notify children that are visible, as those that are hidden are not affected by their parent's
				-- visibility.
				if Child:GetIsVisible() then
					BroadcastVisibilityChange( Child, IsEffectivelyVisible, UpdatedControl )
				end
			end
		end
	end

	--[[
		Sets visibility of the control.
	]]
	function ControlMeta:SetIsVisible( IsVisible )
		if self.Background.GetIsVisible and self.Background:GetIsVisible() == IsVisible then return end

		local WasEffectivelyVisible = true
		if SGUI.IsValid( self.Parent ) then
			WasEffectivelyVisible = self.Parent:ComputeVisibility()
		end

		self.Background:SetIsVisible( IsVisible )
		self:InvalidateParent()

		if not IsVisible then
			self:HideTooltip()
		else
			self:InvalidateMouseState( true )
		end

		-- Notify of the property change after mouse state is updated.
		self:OnPropertyChanged( "IsVisible", IsVisible )

		if WasEffectivelyVisible then
			-- Notify all children that they are now visible/invisible.
			BroadcastVisibilityChange( self, IsVisible, self )
		end

		if not SGUI:IsWindow( self ) then return end

		if IsVisible then
			-- Take focus on show.
			SGUI:SetWindowFocus( self )
		else
			if SGUI.FocusedWindow ~= self then return end

			-- Give focus to the next visible window down on hide.
			SGUI:FocusNextWindowDown()
		end
	end
end

--[[
	Computes the actual visibility state of the object, based on whether it is set to be invisible, or otherwise if it
	has a parent that is not visible.
]]
function ControlMeta:ComputeVisibility()
	if not self:GetIsVisible() then return false end

	if SGUI.IsValid( self.Parent ) then
		return self.Parent:ComputeVisibility()
	end

	return true
end

--[[
	Computes the visibility of the element, taking into account cropping higher up in the tree as well as the visibility
	flag.
]]
function ControlMeta:ComputeVisibilityWithCropping()
	if not self:GetIsVisible() or self:IsCroppedByParent() then return false end

	if SGUI.IsValid( self.Parent ) then
		return self.Parent:ComputeVisibilityWithCropping()
	end

	return true
end

--[[
	Override this for stencilled stuff.
]]
function ControlMeta:GetIsVisible()
	return self.Background:GetIsVisible()
end

SGUI.AddProperty( ControlMeta, "Layout" )

--[[
	Sets a layout handler for the element. This will be updated every time
	a layout-changing property on the element is altered (such as size).
]]
function ControlMeta:SetLayout( Layout, DeferInvalidation )
	self.Layout = Layout

	if Layout then
		Layout:SetParent( self )
		Layout.IsScrollable = self.IsScrollable

		-- Make the element's content size reflect its layout's, as this is more accurate than manually summing/maxing
		-- over each element (and avoids computing the same thing twice).
		if self.GetContentSizeForAxis == ControlMeta.GetContentSizeForAxis then
			self.GetContentSizeForAxis = self.GetContentSizeForAxisFromLayout
		end
	elseif self.GetContentSizeForAxis == ControlMeta.GetContentSizeForAxisFromLayout then
		self.GetContentSizeForAxis = nil
	end

	self:InvalidateLayout( not DeferInvalidation )
end

local function GetLayoutSpacing( self )
	local Margin = self.Layout:GetComputedMargin()
	local Padding = self:GetComputedPadding()
	return Margin, Padding
end

--[[
	This event is called whenever layout is invalidated by a property change.

	By default, it updates the set layout handler.
]]
function ControlMeta:PerformLayout()
	self:UpdateAbsolutePositionChildren()

	if not self.Layout then return end

	local Margin, Padding = GetLayoutSpacing( self )
	local Size = self:GetSize()

	self.Layout:SetPos( Vector2( Margin[ 1 ] + Padding[ 1 ], Margin[ 2 ] + Padding[ 2 ] ) )
	self.Layout:SetSize( Vector2(
		Max( Size.x - Margin[ 5 ] - Padding[ 5 ], 0 ),
		Max( Size.y - Margin[ 6 ] - Padding[ 6 ], 0 )
	) )
	self.Layout:InvalidateLayout( true )
end

function ControlMeta:UpdateAbsolutePositionChildren()
	if not self.ChildrenByPositionType then return end

	local Children = self.ChildrenByPositionType:Get( SGUI.PositionType.ABSOLUTE )
	if not Children then return end

	local Size = self:GetSize()
	for i = 1, #Children do
		local Child = Children[ i ]

		Child:PreComputeWidth()

		local Width = Child:GetComputedSize( 1, Size.x, Size.y )

		-- As in layouts, set the width upfront to avoid needing to auto-wrap twice.
		local ChildSize = Vector2( Width, Child:GetSize().y )
		Child:SetLayoutSize( ChildSize )

		Child:PreComputeHeight( Width )

		ChildSize.y = Child:GetComputedSize( 2, Size.y, Size.x )
		Child:SetLayoutSize( ChildSize )

		local Pos = Child:ComputeAbsolutePosition( Size )
		Child:SetLayoutPos( Pos )
		Child:HandleLayout( 0 )
	end
end

--[[
	Marks the element's parent's layout as invalid, if the element has a parent.

	Pass true to force the layout to update immediately, or leave false/nil to defer until
	the next frame.
]]
function ControlMeta:InvalidateParent( Now )
	if not self.Parent then return end

	self.Parent:InvalidateLayout( Now )

	if self.LayoutParent and self.LayoutParent ~= self.Parent.Layout then
		-- If this is a child of a nested layout, mark the nested layout for invalidation too, otherwise it won't be
		-- re-evaluated as part of the tree.
		self.LayoutParent:InvalidateLayout( Now )
	end
end

--[[
	Marks the element's layout as invalid.

	Pass true to force the layout to update immediately, or leave false/nil to defer until
	the next frame. Deferring is preferred, as there may be multiple property changes in a
	single frame that all trigger layout invalidation.
]]
function ControlMeta:InvalidateLayout( Now )
	self.LayoutIsInvalid = true
	if Now then
		self:HandleLayout( 0, true )
	end
end

do
	-- By default, don't offset an element's position during layout.
	local ZERO = Vector2( 0, 0 )
	function ControlMeta:GetLayoutOffset()
		return ZERO
	end
end

local function Get2DSize( self )
	local Size = self.Background:GetSize()
	-- Normalise the z-component to 0, this can be returned as 1 which breaks equality with Vector2...
	Size.z = 0
	return Size
end

--[[
	Sets the size of the control (background), and invalidates the control's layout.
]]
function ControlMeta:SetSize( SizeVec )
	local OldSize = Get2DSize( self )
	if OldSize == SizeVec then return false end

	-- Apply the size values to a new vector to avoid the caller having a direct reference to the internal value.
	OldSize.x = SizeVec.x
	OldSize.y = SizeVec.y

	self.Size = OldSize

	self.Background:SetSize( SizeVec )
	self:InvalidateLayout()
	self:InvalidateMouseState()
	self:OnPropertyChanged( "Size", SizeVec )

	if self.Parent and self.Parent:GetCroppingBounds() and not self._CallEventsManually then
		self:InvalidateCroppingState()
	end

	return true
end

ControlMeta.GetSize = Get2DSize

--[[
	A simple shortcut method for setting font and potentially scale
	simultaneously.
]]
function ControlMeta:SetFontScale( Font, Scale )
	self:SetFont( Font )
	if Scale then
		self:SetTextScale( Scale )
	end
end

-- This can be overridden by controls that need to update their own items when their background alpha changes.
function ControlMeta:ApplyCalculatedAlphaToBackground( Alpha )
	local Colour = self.Background:GetColor()
	Colour.a = Alpha
	self.Background:SetColor( Colour )
end

function ControlMeta:SetAlpha( Alpha )
	-- Remember this alpha value as the intended alpha for this control.
	self:SetTargetAlpha( Alpha )
	return self:ApplyCalculatedAlphaToBackground( self:CalculateAlpha( Alpha, self:GetParentTargetAlpha() ) )
end

function ControlMeta:SetBackgroundColour( Colour )
	-- Remember the alpha value on the colour as the intended alpha for this control.
	self:SetTargetAlpha( Colour.a )

	-- Copy the colour and compute the actual alpha required to render with the desired alpha, based on inherited alpha.
	self.Background:SetColor( self:ApplyCalculatedAlphaToColour( Colour, self:GetParentTargetAlpha() ) )
end

function ControlMeta:GetAlpha()
	return self.Background:GetColor().a
end

do
	function ControlMeta:ShouldAutoInheritAlpha()
		return self.PropagateAlphaInheritance and self:GetInheritsParentAlpha()
	end

	function ControlMeta:OnAutoInheritAlphaChanged( IsAutoInherit )
		-- To be overridden.
	end

	function ControlMeta:OnAlphaCalculationParametersChanged()
		-- This branching isn't ideal, but it avoids runtime branching when colours are changed (especially useful during
		-- easing).
		local OldCalculateAlpha = self.CalculateAlpha
		local IsInheriting = self:ShouldAutoInheritAlpha()
		if self:GetAlphaMultiplier() == 1 then
			if IsInheriting then
				self.CalculateAlpha = self.CalculateAlphaWithoutMultiplierWithInheritance
				self.ApplyCalculatedAlphaToColour = self.ApplyCalculatedAlphaToColourWithAlphaModifier
			else
				self.CalculateAlpha = self.CalculateAlphaWithoutMultiplierOrInheritance
				self.ApplyCalculatedAlphaToColour = self.ApplyCalculatedAlphaToColourWithoutAlphaModifier
			end
		else
			self.ApplyCalculatedAlphaToColour = self.ApplyCalculatedAlphaToColourWithAlphaModifier

			if IsInheriting then
				self.CalculateAlpha = self.CalculateAlphaWithMultiplierAndInheritance
			else
				self.CalculateAlpha = self.CalculateAlphaWithMultiplierWithoutInheritance
			end
		end
		return OldCalculateAlpha ~= self.CalculateAlpha
	end

	local SetInheritsParentAlpha = ControlMeta.SetInheritsParentAlpha
	function ControlMeta:SetInheritsParentAlpha( InheritsParentAlpha )
		if not SetInheritsParentAlpha( self, InheritsParentAlpha ) then return false end

		if self:OnAlphaCalculationParametersChanged() then
			self:ApplyCalculatedAlphaToBackground(
				self:CalculateAlpha( self:GetTargetAlpha(), self:GetParentTargetAlpha() )
			)

			-- This must have changed if the alpha calculation changed.
			self:OnAutoInheritAlphaChanged( self:ShouldAutoInheritAlpha() )
		end

		if self.PropagateAlphaInheritance and self.Children then
			for Child in self.Children:Iterate() do
				Child:SetInheritsParentAlpha( InheritsParentAlpha )
			end
		end

		return true
	end

	local SetPropagateAlphaInheritance = ControlMeta.SetPropagateAlphaInheritance
	function ControlMeta:SetPropagateAlphaInheritance( PropagateAlphaInheritance )
		if not SetPropagateAlphaInheritance( self, PropagateAlphaInheritance ) then return false end

		if self:OnAlphaCalculationParametersChanged() then
			self:ApplyCalculatedAlphaToBackground(
				self:CalculateAlpha( self:GetTargetAlpha(), self:GetParentTargetAlpha() )
			)

			-- This must have changed if the alpha calculation changed.
			self:OnAutoInheritAlphaChanged( self:ShouldAutoInheritAlpha() )
		end

		if PropagateAlphaInheritance and self.Children then
			local InheritsParentAlpha = self:GetInheritsParentAlpha()
			-- Recurse the flag down the element tree, and ensure everything is inheriting alpha as expected.
			for Child in self.Children:Iterate() do
				Child:SetInheritsParentAlpha( InheritsParentAlpha )
				Child:SetPropagateAlphaInheritance( true )
			end
		end

		return true
	end

	local SetAlphaMultiplier = ControlMeta.SetAlphaMultiplier
	function ControlMeta:SetAlphaMultiplier( AlphaMultiplier )
		local OldMultiplier = self:GetAlphaMultiplier()
		if not SetAlphaMultiplier( self, AlphaMultiplier ) then return false end

		if OldMultiplier == 1 or AlphaMultiplier == 1 then
			self:OnAlphaCalculationParametersChanged()
		end

		-- Always re-apply the alpha as the multiplier affects it regardless of inheritance settings.
		self:ApplyCalculatedAlphaToBackground(
			self:CalculateAlpha( self:GetTargetAlpha(), self:GetParentTargetAlpha() )
		)

		return true
	end

	function ControlMeta:OnParentTargetAlphaChanged( ParentTargetAlpha )
		-- When the parent's target alpha changes, the local alpha needs to be updated to compensate for it.
		-- Note that this doesn't need to be done recursively, the assumption is always that the final value after
		-- multiplying all parent alpha values together will equal the current control's target alpha, so as far as this
		-- control's children are concerned, nothing has changed.
		return self:ApplyCalculatedAlphaToBackground( self:CalculateAlpha( self:GetTargetAlpha(), ParentTargetAlpha ) )
	end

	--[[
		This is called internally whenever the main colour for the control changes.

		The GUIItem system in the game has the option to inherit alpha from parent items. This effectively works as
		a chained multiplication:

		RootAlpha * Child1Alpha * Child2Alpha * ...

		Thus, if a control wishes to be opaque, but it also has translucent parent elements, simply setting the item's
		colour would result in translucency instead of opaquness.

		To compensate for this, each control tracks its target alpha value, that is, the alpha it wants to render with.
		It uses this value to calculate the actual alpha value that, when multiplied by its parent's alpha, will produce
		the intended alpha. Thankfully, the rendering system accepts alpha values > 1, and multiplies them properly.

		For example, if a root element has alpha set to 0.5, but a child wants to be opaque, it needs the following
		actual alpha value set on the GUIItem:

		1 / 0.5 = 2.

		This results in a multiplication of

		0.5 * 2 = 1

		for the item, which renders it as opaque despite its translucent parent item.

		Note that only direct children of an element need to recompute their final alpha value when their parent alpha
		changes, as each item need only compensate for its direct parent's alpha, as its parent is already compensating
		for its parent and so on.
	]]
	local SetTargetAlpha = ControlMeta.SetTargetAlpha
	function ControlMeta:SetTargetAlpha( TargetAlpha )
		if not SetTargetAlpha( self, TargetAlpha ) then return false end

		if self.PropagateAlphaInheritance and self.Children then
			-- Notify all direct children of the change in our target alpha, each child will need to re-compute their
			-- own final alpha value to compensate.
			for Child in self.Children:Iterate() do
				if Child:GetInheritsParentAlpha() then
					Child:OnParentTargetAlphaChanged( TargetAlpha )
				end
			end
		end

		return true
	end

	function ControlMeta:GetParentTargetAlpha()
		local Parent = self.Parent
		if SGUI.IsValid( Parent ) then
			return Parent:GetTargetAlpha()
		end
		-- Always 1 for root elements, nothing gets inherited here.
		return 1
	end

	-- Reduce copying overhead by keeping a single colour object, values get copied by GUIItem:SetColor().
	local ScratchColour = Colour( 0, 0, 0, 0 )

	--[[
		Applies the current alpha calculation to the given colour's alpha value, using the given parent alpha value.

		If automatic alpha inheritance is enabled, then the resulting colour's alpha will compensate for the given
		parent alpha value. Otherwise the alpha will just be multiplied by the control's current alpha multiplier.

		This returns a copy of the given colour, the original colour is not modified. Note that this copy is intended
		to be passed directly into GUIItem:SetColor() and may be modified by subsequent calls, so do not store it
		without first copying it.
	]]
	function ControlMeta:ApplyCalculatedAlphaToColourWithAlphaModifier( Colour, ParentAlpha )
		ScratchColour.r = Colour.r
		ScratchColour.g = Colour.g
		ScratchColour.b = Colour.b
		ScratchColour.a = self:CalculateAlpha( Colour.a, ParentAlpha )
		return ScratchColour
	end

	function ControlMeta:ApplyCalculatedAlphaToColourWithoutAlphaModifier( Colour, ParentAlpha )
		-- Optimisation for the case where no alpha modifications are needed, just return the given colour as-is.
		return Colour
	end
	ControlMeta.ApplyCalculatedAlphaToColour = ControlMeta.ApplyCalculatedAlphaToColourWithoutAlphaModifier

	--[[
		Applies alpha compensation to the given colour for a child GUIItem of the control.

		This will return a copy of the given colour with an alpha vaue that ensures that the final rendered colour has
		the alpha of the given colour, accounting for the given parent alpha value.

		Note that this does not apply the control's alpha multiplier, as that is assumed to be applied through the
		background item already due to inheritance. Also note that this copy is intended to be passed directly into
		GUIItem:SetColor() and may be modified by subsequent calls, so do not store it without first copying it.
	]]
	function ControlMeta:ApplyAlphaCompensationToChildItemColour( Colour, ParentAlpha )
		ScratchColour.r = Colour.r
		ScratchColour.g = Colour.g
		ScratchColour.b = Colour.b
		ScratchColour.a = ParentAlpha == 0 and 0 or ( Colour.a / ParentAlpha )
		return ScratchColour
	end

	function ControlMeta:CalculateAlphaWithoutMultiplierOrInheritance( Alpha, ParentAlpha )
		-- Simplest default case, no alpha multiplier and not inheriting parent alpha with propagation.
		return Alpha
	end
	ControlMeta.CalculateAlpha = ControlMeta.CalculateAlphaWithoutMultiplierOrInheritance

	function ControlMeta:CalculateAlphaWithMultiplierWithoutInheritance( Alpha, ParentAlpha )
		-- Have an alpha multiplier, but not inheriting parent alpha or not set to compensate for it.
		return Alpha * self.AlphaMultiplier
	end

	function ControlMeta:CalculateAlphaWithoutMultiplierWithInheritance( Alpha, ParentAlpha )
		-- No alpha multiplier, but parent alpha is being inherited with compensation enabled, so need to return a value
		-- that will cancel out the parent's alpha to produce this control's desired value.
		if ParentAlpha == 0 then return 0 end
		return Alpha / ParentAlpha
	end

	function ControlMeta:CalculateAlphaWithMultiplierAndInheritance( Alpha, ParentAlpha )
		-- Have an alpha multiplier and want to compensate for parent alpha, so first compute the compensated value,
		-- then multiply it by the multiplier.
		if ParentAlpha == 0 then return 0 end
		return Alpha / ParentAlpha * self.AlphaMultiplier
	end
end

function ControlMeta:GetTextureWidth()
	return self.Background:GetTextureWidth()
end

function ControlMeta:GetTextureHeight()
	return self.Background:GetTextureHeight()
end

function ControlMeta:SetTextureCoordinates( X1, Y1, X2, Y2 )
	self.Background:SetTextureCoordinates( X1, Y1, X2, Y2 )
end

function ControlMeta:SetTexturePixelCoordinates( X1, Y1, X2, Y2 )
	self.Background:SetTexturePixelCoordinates( X1, Y1, X2, Y2 )
end

do
	local Clamp = math.Clamp
	local Min = math.min

	function ControlMeta:EvaluateBorderRadii( Size, BorderRadii )
		-- Doesn't make sense for border radius to exceed half the box along either axis.
		local MaxRadius = Min( Size.x * 0.5, Size.y * 0.5 )
		return Colour(
			-- Use the y-axis as the reference value as it makes more sense to want to make borders relative to height
			-- rather than width, most elements are wider than they are tall.
			Clamp( BorderRadii[ 1 ] and BorderRadii[ 1 ]:GetValue( Size.y, self, 2, Size.x ) or 0, 0, MaxRadius ),
			Clamp( BorderRadii[ 2 ] and BorderRadii[ 2 ]:GetValue( Size.y, self, 2, Size.x ) or 0, 0, MaxRadius ),
			Clamp( BorderRadii[ 3 ] and BorderRadii[ 3 ]:GetValue( Size.y, self, 2, Size.x ) or 0, 0, MaxRadius ),
			Clamp( BorderRadii[ 4 ] and BorderRadii[ 4 ]:GetValue( Size.y, self, 2, Size.x ) or 0, 0, MaxRadius )
		)
	end

	local function SetBorderParameters( self, Size, BorderRadii )
		self.Background:SetFloat2Parameter( "size", Size )

		local AbsoluteRadii = self:EvaluateBorderRadii( Size, BorderRadii )
		self.Background:SetFloat4Parameter( "radii", AbsoluteRadii )
		self.AbsoluteBorderRadii = AbsoluteRadii
	end

	local function UpdateShaderSize( self, Size )
		return SetBorderParameters( self, Size, self.BorderRadii )
	end

	local function SetupRoundedCorners( self, BorderRadii )
		self.Background:SetShader( SGUI.Shaders.RoundedRect )

		SetBorderParameters( self, self:GetSize(), BorderRadii )

		self:AddPropertyChangeListener( "Size", UpdateShaderSize )
	end

	local function RemoveRoundedCorners( self )
		self.Background:SetShader( "shaders/GUIBasic.surface_shader" )
		self:RemovePropertyChangeListener( "Size", UpdateShaderSize )
		self.BorderRadii = nil
		self.AbsoluteBorderRadii = nil

		self:OnPropertyChanged( "TopLeftBorderRadius", nil )
		self:OnPropertyChanged( "TopRightBorderRadius", nil )
		self:OnPropertyChanged( "BottomRightBorderRadius", nil )
		self:OnPropertyChanged( "BottomLeftBorderRadius", nil )
	end

	local function InitialiseBorderRadii( self, BorderRadii )
		if not BorderRadii then
			BorderRadii = { nil, nil, nil, nil }
			self.BorderRadii = BorderRadii
		end
		return BorderRadii
	end

	local function HasOtherRadii( BorderRadii, Index )
		if not BorderRadii then return false end

		for i = 1, 4 do
			if i ~= Index and BorderRadii[ i ] then
				return true
			end
		end

		return false
	end

	local function SetBorderRadius( self, Index, Radius, Key )
		local BorderRadii = self.BorderRadii
		if not BorderRadii and not Radius then return false end

		Radius = Radius and SGUI.Layout.ToUnit( Radius )

		if BorderRadii and BorderRadii[ Index ] == Radius then return false end

		if Radius or HasOtherRadii( BorderRadii, Index ) then
			BorderRadii = InitialiseBorderRadii( self, BorderRadii )
			BorderRadii[ Index ] = Radius
			SetupRoundedCorners( self, BorderRadii )
			self:OnPropertyChanged( Key, Radius )
		else
			RemoveRoundedCorners( self )
		end

		return true
	end

	function ControlMeta:SetTopLeftBorderRadius( TopLeftBorderRadius )
		return SetBorderRadius( self, 1, TopLeftBorderRadius, "TopLeftBorderRadius" )
	end

	function ControlMeta:GetTopLeftBorderRadius()
		return self.BorderRadii and self.BorderRadii[ 1 ]
	end

	function ControlMeta:SetTopRightBorderRadius( TopRightBorderRadius )
		return SetBorderRadius( self, 2, TopRightBorderRadius, "TopRightBorderRadius" )
	end

	function ControlMeta:GetTopRightBorderRadius()
		return self.BorderRadii and self.BorderRadii[ 2 ]
	end

	function ControlMeta:SetBottomRightBorderRadius( BottomRightBorderRadius )
		return SetBorderRadius( self, 3, BottomRightBorderRadius, "BottomRightBorderRadius" )
	end

	function ControlMeta:GetBottomRightBorderRadius()
		return self.BorderRadii and self.BorderRadii[ 3 ]
	end

	function ControlMeta:SetBottomLeftBorderRadius( BottomLeftBorderRadius )
		return SetBorderRadius( self, 4, BottomLeftBorderRadius, "BottomLeftBorderRadius" )
	end

	function ControlMeta:GetBottomLeftBorderRadius()
		return self.BorderRadii and self.BorderRadii[ 4 ]
	end

	function ControlMeta:SetBorderRadii( BorderRadii )
		local CurrentBorderRadii = self.BorderRadii
		if not CurrentBorderRadii and not BorderRadii then return false end

		if
			CurrentBorderRadii and BorderRadii and
			CurrentBorderRadii[ 1 ] == BorderRadii[ 1 ] and
			CurrentBorderRadii[ 2 ] == BorderRadii[ 2 ] and
			CurrentBorderRadii[ 3 ] == BorderRadii[ 3 ] and
			CurrentBorderRadii[ 4 ] == BorderRadii[ 4 ]
		then
			return false
		end

		if BorderRadii then
			CurrentBorderRadii = InitialiseBorderRadii( self, CurrentBorderRadii )
			CurrentBorderRadii[ 1 ] = SGUI.Layout.ToUnit( BorderRadii[ 1 ] )
			CurrentBorderRadii[ 2 ] = SGUI.Layout.ToUnit( BorderRadii[ 2 ] )
			CurrentBorderRadii[ 3 ] = SGUI.Layout.ToUnit( BorderRadii[ 3 ] )
			CurrentBorderRadii[ 4 ] = SGUI.Layout.ToUnit( BorderRadii[ 4 ] )
			SetupRoundedCorners( self, CurrentBorderRadii )

			self:OnPropertyChanged( "TopLeftBorderRadius", CurrentBorderRadii[ 1 ] )
			self:OnPropertyChanged( "TopRightBorderRadius", CurrentBorderRadii[ 2 ] )
			self:OnPropertyChanged( "BottomRightBorderRadius", CurrentBorderRadii[ 3 ] )
			self:OnPropertyChanged( "BottomLeftBorderRadius", CurrentBorderRadii[ 4 ] )
		else
			RemoveRoundedCorners( self )
		end

		return true
	end

	function ControlMeta:GetBorderRadii()
		return self.BorderRadii
	end

	function ControlMeta:SetUniformBorderRadius( Radius )
		Radius = Radius and SGUI.Layout.ToUnit( Radius )
		return self:SetBorderRadii( Radius and { Radius, Radius, Radius, Radius } or nil )
	end
end

--[[
	Alignment controls whether elements are placed at the start or end of a layout.

	For example, MIN in vertical layout places from the top, while MAX places from
	the bottom.
]]
SGUI.LayoutAlignment = {
	MIN = 1,
	MAX = 2,
	CENTRE = 3
}

SGUI.AddProperty( ControlMeta, "Alignment", SGUI.LayoutAlignment.MIN, { "InvalidatesParent" } )

-- Cross-axis alignment controls how an element is aligned on the opposite axis to the layout direction.
-- For example, an element in a horizontal layout uses the cross-axis alignment to align itself vertically.
SGUI.AddProperty( ControlMeta, "CrossAxisAlignment", SGUI.LayoutAlignment.MIN, { "InvalidatesParent" } )

-- AutoSize controls how to resize the control during layout. You should pass a UnitVector, with
-- your dynamic units (e.g. GUIScaled, Percentage).
SGUI.AddProperty( ControlMeta, "AutoSize", nil, { "InvalidatesParent" } )

-- AutoFont provides a way to set the font size automatically at layout time.
SGUI.AddProperty( ControlMeta, "AutoFont", nil, { "InvalidatesParent" } )

-- AspectRatio provides a way to make a control's height depend on its width, computed at layout time.
-- This only works if the control has an AutoSize set, and will ignore the height value of the AutoSize entirely.
SGUI.AddProperty( ControlMeta, "AspectRatio", nil, { "InvalidatesParent" } )

-- Fill controls whether the element should have its size computed automatically during layout.
SGUI.AddProperty( ControlMeta, "Fill", nil, { "InvalidatesParent" } )

-- Margin controls separation of elements in layouts.
SGUI.AddProperty( ControlMeta, "Margin", nil, { "InvalidatesParent" } )

-- Padding controls the space from the element borders to where the layout may place elements.
SGUI.AddProperty( ControlMeta, "Padding", nil, { "InvalidatesLayout" } )

-- Offsets for absolutely positioned elements.
SGUI.AddProperty( ControlMeta, "LeftOffset", nil, { "InvalidatesParent" } )
SGUI.AddProperty( ControlMeta, "TopOffset", nil, { "InvalidatesParent" } )

SGUI.PositionType = {
	NONE = 1,
	ABSOLUTE = 2
}

SGUI.AddProperty( ControlMeta, "PositionType", SGUI.PositionType.NONE, { "InvalidatesParent" } )

function ControlMeta:SetPositionType( PositionType )
	local OldPositionType = self:GetPositionType()
	if OldPositionType == PositionType then return end

	self.PositionType = PositionType

	local Parent = self.Parent
	if Parent then
		Parent.ChildrenByPositionType:RemoveKeyValue( OldPositionType, self )
		Parent.ChildrenByPositionType:Add( PositionType, self )
	end
end

function ControlMeta:ComputeAbsolutePosition( ParentSize )
	local LeftOffset = SGUI.Layout.ToUnit( self:GetLeftOffset() )
	local TopOffset = SGUI.Layout.ToUnit( self:GetTopOffset() )

	local OriginX, OriginY = 0, 0
	local Alignment = self:GetAlignment()
	if Alignment == SGUI.LayoutAlignment.CENTRE then
		OriginX = ParentSize.x * 0.5
	elseif Alignment == SGUI.LayoutAlignment.MAX then
		OriginX = ParentSize.x
	end

	local CrossAxisAlignment = self:GetCrossAxisAlignment()
	if CrossAxisAlignment == SGUI.LayoutAlignment.CENTRE then
		OriginY = ParentSize.y * 0.5
	elseif Alignment == SGUI.LayoutAlignment.MAX then
		OriginY = ParentSize.y
	end

	return Vector2(
		OriginX + LeftOffset:GetValue( ParentSize.x, self, 1, ParentSize.y ),
		OriginY + TopOffset:GetValue( ParentSize.y, self, 2, ParentSize.x )
	)
end

function ControlMeta:IterateChildren()
	return self.Children:Iterate()
end

do
	local function IterateLayoutAncestors( _, Parent )
		return Parent.LayoutParent or Parent.Parent
	end

	function ControlMeta:IterateLayoutAncestors()
		return IterateLayoutAncestors, nil, self
	end
end

function ControlMeta:GetParentSize()
	if self.LayoutParent then
		return self.LayoutParent:GetSize()
	end

	return self.Parent and self.Parent:GetSize() or Vector2( SGUI.GetScreenSize() )
end

local VectorAxis = {
	"x", "y"
}
local OppositeAxis = {
	2, 1
}

function ControlMeta:GetMaxSizeAlongAxis( Axis )
	local Padding = self:GetComputedPadding()
	local TotalIndex = Axis + 4

	local Total = Padding[ TotalIndex ]
	local ParentSize = self:GetParentSize()
	local MainParentSize = ParentSize[ VectorAxis[ Axis ] ]
	local OppositeAxisParentSize = ParentSize[ VectorAxis[ OppositeAxis[ Axis ] ] ]
	local MaxChildSize = 0

	for Child in self:IterateChildren() do
		Child:PreComputeWidth()

		-- This only works if the child's size does not depend on the parent's.
		-- Otherwise it's a circular dependency and it won't be correct.
		local ChildSize = Child:GetComputedSize( Axis, MainParentSize, OppositeAxisParentSize ) +
			Child:GetComputedMargin()[ TotalIndex ]

		MaxChildSize = Max( MaxChildSize, ChildSize )
	end

	return Max( Total + MaxChildSize, 0 )
end

function ControlMeta:GetContentSizeForAxis( Axis )
	local Padding = self:GetComputedPadding()
	local TotalIndex = Axis + 4

	local Total = Padding[ TotalIndex ]
	local ParentSize = self:GetParentSize()
	local MainParentSize = ParentSize[ VectorAxis[ Axis ] ]
	local OppositeAxisParentSize = ParentSize[ VectorAxis[ OppositeAxis[ Axis ] ] ]

	for Child in self:IterateChildren() do
		Child:PreComputeWidth()

		-- This only works if the child's size does not depend on the parent's.
		-- Otherwise it's a circular dependency and it won't be correct.
		Total = Total + Child:GetComputedSize( Axis, MainParentSize, OppositeAxisParentSize )
		Total = Total + Child:GetComputedMargin()[ TotalIndex ]
	end

	return Max( Total, 0 )
end

function ControlMeta:GetContentSizeForAxisFromLayout( Axis )
	self:HandleLayout( 0, true )

	local Margin, Padding = GetLayoutSpacing( self )
	return Padding[ Axis + 4 ] + Margin[ Axis + 4 ] + self.Layout:GetContentSizeForAxis( Axis )
end

-- You can either use AutoSize as part of a layout, or on its own by passing true for UpdateNow.
function ControlMeta:SetAutoSize( AutoSize, UpdateNow )
	self.AutoSize = AutoSize

	if not UpdateNow then return end

	local ParentSize = self:GetParentSize()

	self:SetSize(
		Vector2(
			self:GetComputedSize( 1, ParentSize.x, ParentSize.y ),
			self:GetComputedSize( 2, ParentSize.y, ParentSize.x )
		)
	)
end

do
	local function SuppressInvalidation() end

	-- Called before a layout computes the current width of the element.
	function ControlMeta:PreComputeWidth()
		if not self.AutoFont then return end

		local FontFamily = self.AutoFont.Family
		local Size = self.AutoFont.Size:GetValue()

		-- Suppress invalidating the parent element as it'll see the size change immediately here.
		self.InvalidateParent = SuppressInvalidation
		self:SetFontScale( SGUI.FontManager.GetFontForAbsoluteSize( FontFamily, Size, self.GetText and self:GetText() ) )
		self.InvalidateParent = nil
	end

	-- Called before a layout computes the current height of the element.
	-- Override to add wrapping logic.
	function ControlMeta:PreComputeHeight( Width )
		if not self.AspectRatio or not self.AutoSize then return end

		-- Make height always relative to width.
		self.AutoSize[ 2 ] = SGUI.Layout.Units.Absolute( Width * self.AspectRatio )
	end
end

--[[
	Computes the size of the control based on the units provided.
]]
function ControlMeta:GetComputedSize( Index, ParentSize, OppositeAxisParentSize )
	local Size = self.AutoSize
	if Size then
		-- Auto-size means use our set auto-size units relative to the passed in size.
		return Max( Size[ Index ]:GetValue( ParentSize, self, Index, OppositeAxisParentSize ), 0 )
	end

	-- Fill means take the size given.
	if self:GetFill() then
		return ParentSize
	end

	-- No auto-size means the element has a fixed size.
	return self:GetSizeForAxis( Index )
end

function ControlMeta:ComputeSpacing( Spacing )
	if not Spacing then
		return { 0, 0, 0, 0, 0, 0 }
	end

	local ParentSize = self:GetParentSize()
	local Computed = {
		Spacing[ 1 ]:GetValue( ParentSize.x, self, 1, ParentSize.y ),
		Spacing[ 2 ]:GetValue( ParentSize.y, self, 2, ParentSize.x ),
		Spacing[ 3 ]:GetValue( ParentSize.x, self, 1, ParentSize.y ),
		Spacing[ 4 ]:GetValue( ParentSize.y, self, 2, ParentSize.x ),
		0,
		0
	}
	-- Pre-compute totals for each axis as this is a common operation.
	Computed[ 5 ] = Computed[ 1 ] + Computed[ 3 ]
	Computed[ 6 ] = Computed[ 2 ] + Computed[ 4 ]

	return Computed
end

function ControlMeta:GetComputedPadding()
	return self:ComputeSpacing( self.Padding )
end

function ControlMeta:GetComputedMargin()
	return self:ComputeSpacing( self.Margin )
end

function ControlMeta:GetSizeForAxis( Axis )
	return self:GetSize()[ VectorAxis[ Axis ] ]
end

function ControlMeta:GetSizeForOppositeAxis( Axis )
	return self:GetSizeForAxis( OppositeAxis[ Axis ] )
end

--[[
	Sets the position of an SGUI control.

	Controls may override this.
]]
function ControlMeta:SetPos( Pos )
	local OldPos = self.Background:GetPosition()
	if Pos == OldPos then return false end

	-- Apply the position values to a new vector to avoid the caller having a direct reference to the internal value.
	OldPos.x = Pos.x
	OldPos.y = Pos.y

	self.Pos = OldPos

	self.Background:SetPosition( Pos )
	self:InvalidateMouseState()
	self:OnPropertyChanged( "Pos", Pos )

	if self.Parent and self.Parent:GetCroppingBounds() and not self._CallEventsManually then
		self:InvalidateCroppingState()
	end

	return true
end

function ControlMeta:GetPos()
	return self.Background:GetPosition()
end

--[[
	Returns the absolute position of the control on the screen.
]]
function ControlMeta:GetScreenPos()
	return self.Background:GetScreenPosition( SGUI.GetScreenSize() )
end

-- By default, layout position and size point at the real position and size with no easing involved.
-- Note that these call the appropriate method rather than just alias the base method to account for controls that
-- override SetPos/GetPos/SetSize/GetSize.
function ControlMeta:SetLayoutPos( Pos )
	return self:SetPos( Pos )
end
function ControlMeta:GetLayoutPos()
	return self:GetPos()
end
function ControlMeta:SetLayoutSize( Size )
	return self:SetSize( Size )
end
function ControlMeta:GetLayoutSize()
	return self:GetSize()
end

do
	local function IsZero( Vec )
		return Vec.x == 0 and Vec.y == 0
	end

	local function ResolveCropping( self )
		-- Recurse upwards until a parent element with a cropping rectange is found.
		-- In theory the actual cropping could consist of multiple boxes which cut parts of each other out, but this
		-- is ultimately just a heuristic check so doesn't need perfect accuracy. Most of the time, cropping boxes
		-- are strictly nested within each other and thus the closest parent is the correct box.
		local Parent = self.Background:GetParent()
		while Parent do
			-- This returns values even when cropping is disabled, so have to assume (0, 0) -> (0, 0) means disabled...
			local MinCorner, MaxCorner = Parent:GetCropRectangle()
			if MinCorner and not ( IsZero( MinCorner ) and IsZero( MaxCorner ) ) then
				local Pos = Parent:GetScreenPosition( SGUI.GetScreenSize() )
				return Pos + MinCorner, Pos + MaxCorner
			end
			Parent = Parent:GetParent()
		end
		return nil
	end

	local function IsPointCropped( ScreenPos, Mins, Maxs )
		return ScreenPos.x < Mins.x or ScreenPos.y < Mins.y or ScreenPos.x > Maxs.x or ScreenPos.y > Maxs.y
	end

	local function GetLayoutPos( self )
		return self.LayoutPos
	end

	local function SetLayoutPosWithTransition( self, Pos )
		if self.LayoutPos == Pos then return false end

		-- Copy the position to avoid callers having a reference to the internal value.
		Pos = Vector( Pos )

		self.LayoutPos = Pos

		local Mins, Maxs = ResolveCropping( self )
		if Mins then
			local CurrentScreenPos = self:GetScreenPos()
			local NewScreenPos = CurrentScreenPos + ( Pos - self:GetPos() )
			local Size = self:GetLayoutSize()
			if
				IsPointCropped( NewScreenPos, Mins, Maxs ) and
				IsPointCropped( NewScreenPos + Size, Mins, Maxs ) and
				IsPointCropped( CurrentScreenPos, Mins, Maxs ) and
				IsPointCropped( CurrentScreenPos + Size, Mins, Maxs )
			then
				-- Both the current position and intended position do not appear to be visible, so it would be wasted
				-- effort to ease them. Just update the position immediately.
				self:StopMoving( self.Background )
				self:SetPos( Pos )
				return true
			end
		end

		self.LayoutPosTransition.EndValue = Pos
		self.LayoutPosTransition.StartValue = nil
		self:ApplyTransition( self.LayoutPosTransition )

		return true
	end

	local function SetLayoutPos( self, Pos )
		-- First update, set the position immediately.
		self.LayoutPos = Vector( Pos )
		-- Subsequent position updates will be eased.
		self.SetLayoutPos = SetLayoutPosWithTransition
		self.GetLayoutPos = GetLayoutPos
		return self:SetPos( Pos )
	end

	local function GetLayoutSize( self )
		return self.LayoutSize
	end

	local function SetLayoutSizeWithTransition( self, Size )
		if self.LayoutSize == Size then return false end

		-- Copy the size to avoid callers having a reference to the internal value.
		Size = Vector( Size )

		self.LayoutSize = Size

		local Mins, Maxs = ResolveCropping( self )
		if Mins then
			local Pos = self:GetScreenPos()
			local CurrentSize = self:GetSize()
			if
				IsPointCropped( Pos, Mins, Maxs ) and
				IsPointCropped( Pos + Size, Mins, Maxs ) and
				IsPointCropped( Pos + CurrentSize, Mins, Maxs )
			then
				-- Both the current box and intended box do not appear to be visible, so it would be wasted
				-- effort to ease them. Just update the size immediately.
				self:StopResizing( self.Background )
				self:SetSize( Size )
				return true
			end
		end

		self.LayoutSizeTransition.EndValue = Size
		self.LayoutSizeTransition.StartValue = nil
		self:ApplyTransition( self.LayoutSizeTransition )

		return true
	end

	local function SetLayoutSize( self, Size )
		-- First update, set the size immediately.
		self.LayoutSize = Vector( Size )
		-- Subsequent size updates will be eased.
		self.SetLayoutSize = SetLayoutSizeWithTransition
		self.GetLayoutSize = GetLayoutSize
		return self:SetSize( Size )
	end

	--[[
		Sets the transition parameters to use to apply easing to position updates that originate from computed layout.

		This allows for automatic easing as part of the layout process without needing to deal with manual positioning.

		Note that the first time the position is set on a control, no easing will occur.

		Input: The transition parameters to use when easing the position after layout (see ApplyTransition for the
		structure, note that "Type" and "Element" are ignored as they are always "Move" and nil (self.Background)
		respectively).
	]]
	function ControlMeta:SetLayoutPosTransition( Transition )
		if self.LayoutPosTransition == Transition then return false end

		self.LayoutPosTransition = Transition

		if Transition then
			Transition.Type = "Move"
			Transition.Element = nil

			if self.Pos == nil then
				-- Position hasn't been set yet, the first movement should be instant.
				-- Leave GetLayoutPos pointing at GetPos until self.LayoutPos is initially populated.
				self.SetLayoutPos = SetLayoutPos
			else
				-- Position has been set before, animate to new positions and set self.LayoutPos for reading.
				self.LayoutPos = self:GetPos()
				self.SetLayoutPos = SetLayoutPosWithTransition
				self.GetLayoutPos = GetLayoutPos
			end
		else
			-- Reset back to the default methods.
			self.SetLayoutPos = nil
			self.GetLayoutPos = nil
			self.LayoutPos = nil
		end

		return true
	end

	--[[
		Sets the transition parameters to use to apply easing to size updates that originate from computed layout.

		This allows for automatic easing as part of the layout process without needing to deal with manual resizing.

		Note that the first time the size is set on a control, no easing will occur.

		Input: The transition parameters to use when easing the size after layout (see ApplyTransition for the
		structure, note that "Type" and "Element" are ignored as they are always "Size" and nil (self.Background)
		respectively).
	]]
	function ControlMeta:SetLayoutSizeTransition( Transition )
		if self.LayoutSizeTransition == Transition then return false end

		self.LayoutSizeTransition = Transition

		if Transition then
			Transition.Type = "Size"
			Transition.Element = nil

			if self.Size == nil then
				-- Size hasn't been set yet, the first resize should be instant.
				-- Leave GetLayoutSize pointing at GetSize until self.LayoutSize is initially populated.
				self.SetLayoutSize = SetLayoutSize
			else
				-- Size has been set before, animate to new sizes and set self.LayoutSize for reading.
				self.LayoutSize = self:GetSize()
				self.SetLayoutSize = SetLayoutSizeWithTransition
				self.GetLayoutSize = GetLayoutSize
			end
		else
			-- Reset back to the default methods.
			self.SetLayoutSize = nil
			self.GetLayoutSize = nil
			self.LayoutSize = nil
		end

		return true
	end
end

do
	local Anchors = {
		TopLeft = { GUIItem.Left, GUIItem.Top },
		TopMiddle = { GUIItem.Middle, GUIItem.Top },
		TopRight = { GUIItem.Right, GUIItem.Top },

		CentreLeft = { GUIItem.Left, GUIItem.Center },
		CentreMiddle = { GUIItem.Middle, GUIItem.Center },
		CentreRight = { GUIItem.Right, GUIItem.Center },

		CenterLeft = { GUIItem.Left, GUIItem.Center },
		CenterMiddle = { GUIItem.Middle, GUIItem.Center },
		CenterRight = { GUIItem.Right, GUIItem.Center },

		BottomLeft = { GUIItem.Left, GUIItem.Bottom },
		BottomMiddle = { GUIItem.Middle, GUIItem.Bottom },
		BottomRight = { GUIItem.Right, GUIItem.Bottom }
	}
	SGUI.Anchors = Anchors

	local AnchorFractions = {
		TopLeft = Vector2( 0, 0 ),
		TopMiddle = Vector2( 0.5, 0 ),
		TopRight = Vector2( 1, 0 ),

		CentreLeft = Vector2( 0, 0.5 ),
		CentreMiddle = Vector2( 0.5, 0.5 ),
		CentreRight = Vector2( 1, 0.5 ),

		CenterLeft = Vector2( 0, 0.5 ),
		CenterMiddle = Vector2( 0.5, 0.5 ),
		CenterRight = Vector2( 1, 0.5 ),

		BottomLeft = Vector2( 0, 1 ),
		BottomMiddle = Vector2( 0.5, 1 ),
		BottomRight = Vector2( 1, 1 ),

		[ GUIItem.Left ] = 0,
		[ GUIItem.Middle ] = 0.5,
		[ GUIItem.Right ] = 1,
		[ GUIItem.Top ] = 0,
		[ GUIItem.Center ] = 0.5,
		[ GUIItem.Bottom ] = 1
	}

	local NewScalingFlag = GUIItem.CorrectScaling

	--[[
		Sets the origin anchors for the control.
	]]
	function ControlMeta:SetAnchor( X, Y )
		local UsesNewScaling = self.Background:IsOptionFlagSet( NewScalingFlag )
		if IsType( X, "string" ) then
			if UsesNewScaling then
				local Anchor = Shine.AssertAtLevel( AnchorFractions[ X ], "Unknown anchor type: %s", 3, X )
				self.Background:SetAnchor( Anchor )
				return
			end

			local Anchor = Shine.AssertAtLevel( Anchors[ X ], "Unknown anchor type: %s", 3, X )
			self.Background:SetAnchor( Anchor[ 1 ], Anchor[ 2 ] )
		else
			if UsesNewScaling then
				self.Background:SetAnchor( Vector2( AnchorFractions[ X ], AnchorFractions[ Y ] ) )
				return
			end

			self.Background:SetAnchor( X, Y )
		end
	end

	--[[
		Sets the origin anchors using a fractional value for the control.
	]]
	function ControlMeta:SetAnchorFraction( X, Y )
		Shine.AssertAtLevel(
			self.Background:IsOptionFlagSet( NewScalingFlag ),
			"Background element must have GUIItem.CorrectScaling flag set to use SetAnchorFraction!",
			3
		)

		self.Background:SetAnchor( Vector2( X, Y ) )
	end

	--[[
		Sets the local origin of the given element (i.e. 0, 0 means position determines where the top-left corner is,
		0.5, 0.5 means position determines where the centre of the element is).

		This also affects the origin of scaling applied to the element.
	]]
	function ControlMeta:SetHotSpot( X, Y )
		Shine.AssertAtLevel(
			self.Background:IsOptionFlagSet( NewScalingFlag ),
			"Background element must have GUIItem.CorrectScaling flag set to use SetHotSpot!",
			3
		)

		if IsType( X, "string" ) then
			local HotSpot = Shine.AssertAtLevel( AnchorFractions[ X ], "Unknown hotspot type: %s", 3, X )
			self.Background:SetHotSpot( HotSpot )
		else
			self.Background:SetHotSpot( X, Y )
		end
	end
end

function ControlMeta:GetAnchor()
	local X = self.Background:GetXAnchor()
	local Y = self.Background:GetYAnchor()

	return X, Y
end

do
	-- We call this so many times it really needs to be local, not global.
	local GetCursorPos = SGUI.GetCursorPos

	local function IsInBox( BoxX, BoxY, BoxEndX, BoxEndY, X, Y )
		return X >= BoxX and X < BoxEndX and Y >= BoxY and Y < BoxEndY
	end

	local function IsInElementBox( ElementPos, BoxX, BoxY, BoxEndX, BoxEndY )
		local X, Y = GetCursorPos()
		X = X - ElementPos.x
		Y = Y - ElementPos.y
		return IsInBox( BoxX, BoxY, BoxEndX, BoxEndY, X, Y ), X, Y
	end

	local function ApplyMultiplier( Size, Mult )
		local BoxX, BoxY = 0, 0
		local BoxEndX, BoxEndY = Size.x, Size.y

		if Mult then
			local HalfW = BoxEndX * 0.5
			local HalfH = BoxEndY * 0.5

			if IsType( Mult, "number" ) then
				Size = Size * Mult
			else
				Size.x = Size.x * Mult.x
				Size.y = Size.y * Mult.y
			end

			-- Re-adjust the starting point of the box to ensure the multiplier is applied from the centre of the box.
			local W, H = Size.x, Size.y
			BoxX = HalfW - W * 0.5
			BoxY = HalfH - H * 0.5
			BoxEndX = BoxX + W
			BoxEndY = BoxY + H
		end

		return BoxX, BoxY, BoxEndX, BoxEndY
	end

	--[[
		Gets whether the mouse cursor is inside the given bounds, relative to the given GUIItem.

		Inputs:
			1. Element to check.
			2. Width of the bounding box.
			3. Height of the bounding box.
		Outputs:
			1. Boolean value to indicate whether the mouse is inside.
			2. X position of the mouse relative to the element.
			3. Y position of the mouse relative to the element.
	]]
	function ControlMeta:MouseInBounds( Element, BoundsW, BoundsH )
		local Pos = Element:GetScreenPosition( SGUI.GetScreenSize() )
		return IsInElementBox( Pos, 0, 0, BoundsW, BoundsH )
	end

	--[[
		Gets whether the mouse cursor is inside the bounds of a GUIItem.
		The multiplier will increase or reduce the size used to calculate the bounds relative to the centre, e.g.
		a value of 1.25 will add 12.5% of the bounding box to all sides.

		Inputs:
			1. Element to check.
			2. Multiplier value to increase/reduce the size of the bounding box.
		Outputs:
			1. Boolean value to indicate whether the mouse is inside.
			2. X position of the mouse relative to the element.
			3. Y position of the mouse relative to the element.
	]]
	function ControlMeta:MouseIn( Element, Mult )
		if not Element then return end

		local Pos = Element:GetScreenPosition( SGUI.GetScreenSize() )
		local Size = Element:GetScaledSize()

		return IsInElementBox( Pos, ApplyMultiplier( Size, Mult ) )
	end

	--[[
		Gets the bounds to use when checking whether the mouse is in a control.

		Override this to change how mouse enter/leave detection works.
	]]
	function ControlMeta:GetMouseBounds()
		return self:GetSize()
	end

	--[[
		Similar to MouseIn, but uses the control's native GetScreenPos and GetMouseBounds instead
		of a GUIItem's.

		Useful for controls whose size/position does not match a GUIItem directly.
	]]
	function ControlMeta:MouseInControl( Mult )
		local Pos = self:GetScreenPos()
		local Size = self:GetMouseBounds()

		return IsInElementBox( Pos, ApplyMultiplier( Size, Mult ) )
	end

	function ControlMeta:MouseInCached()
		local LastCheck = self.__LastMouseInCheckFrame
		local FrameNum = SGUI.FrameNumber()

		if LastCheck ~= FrameNum then
			self.__LastMouseInCheckFrame = FrameNum

			local In, X, Y = self:MouseInControl()
			local CachedResult = self.__LastMouseInCheck
			if not CachedResult then
				CachedResult = TableNew( 3, 0 )
				self.__LastMouseInCheck = CachedResult
			end

			CachedResult[ 1 ] = In
			CachedResult[ 2 ] = X
			CachedResult[ 3 ] = Y

			return In, X, Y
		end

		local Check = self.__LastMouseInCheck
		return Check[ 1 ], Check[ 2 ], Check[ 3 ]
	end
end

function ControlMeta:HasMouseFocus()
	return SGUI.MouseDownControl == self
end

do
	local function SubtractValues( End, Start )
		if IsType( End, "number" ) or not End.r then
			return End - Start
		end

		return SGUI.ColourSub( End, Start )
	end

	local function CopyValue( Value )
		if IsType( Value, "number" ) then
			return Value
		end

		if SGUI.IsColour( Value ) then
			return SGUI.CopyColour( Value )
		end

		return Vector2( Value.x, Value.y )
	end

	local function LinearEase( Progress )
		return Progress
	end

	local function OnUpdate( self, Element, EasingData ) end

	local Max = math.max

	function ControlMeta:EaseValue( Element, Start, End, Delay, Duration, Callback, EasingHandlers )
		self.EasingProcesses = self.EasingProcesses or UnorderedMap()

		local Easers = self.EasingProcesses:Get( EasingHandlers )
		if not Easers then
			Easers = UnorderedMap()
			self.EasingProcesses:Add( EasingHandlers, Easers )
		end

		Element = Element or self.Background

		local EasingData = Easers:Get( Element )
		if not EasingData then
			EasingData = {}
			Easers:Add( Element, EasingData )
		end

		EasingData.Element = Element
		Start = Start or EasingHandlers.Getter( self, Element )
		EasingData.Start = Start
		EasingData.End = End
		EasingData.Diff = SubtractValues( End, Start )
		EasingData.CurValue = CopyValue( Start )
		EasingData.Easer = EasingHandlers.Easer
		EasingData.EaseFunc = LinearEase

		EasingData.StartTime = Clock() + Delay
		EasingData.Duration = Duration
		EasingData.Elapsed = Max( -Delay, 0 )
		EasingData.LastUpdate = Clock()

		EasingData.OnUpdate = OnUpdate
		EasingData.Callback = Callback

		if EasingHandlers.Init then
			EasingHandlers.Init( self, Element, EasingData )
		end

		if Delay <= 0 then
			EasingHandlers.Setter( self, Element, Start, EasingData )
		end

		return EasingData
	end
end

do
	local function UpdateEasing( self, Time, DeltaTime, EasingHandler, Easings, Element, EasingData )
		EasingData.Elapsed = EasingData.Elapsed + Max( DeltaTime, Time - EasingData.LastUpdate )

		local Duration = EasingData.Duration
		local Elapsed = EasingData.Elapsed
		if Elapsed <= Duration then
			local Progress = EasingData.EaseFunc( Elapsed / Duration, EasingData.Power )
			EasingData.Easer( self, Element, EasingData, Progress )
			EasingHandler.Setter( self, Element, EasingData.CurValue, EasingData )
			EasingData.OnUpdate( self, Element, EasingData )
		else
			EasingHandler.Setter( self, Element, EasingData.End, EasingData )
			if EasingHandler.OnComplete then
				EasingHandler.OnComplete( self, Element, EasingData )
			end

			Easings:Remove( Element )

			if EasingData.Callback then
				EasingData.Callback( self, Element )
			end
		end
	end

	function ControlMeta:HandleEasing( Time, DeltaTime )
		if not self.EasingProcesses or self.EasingProcesses:IsEmpty() then return end

		for EasingHandler, Easings in self.EasingProcesses:Iterate() do
			for Element, EasingData in Easings:Iterate() do
				local Start = EasingData.StartTime

				if Start <= Time then
					UpdateEasing( self, Time, DeltaTime, EasingHandler, Easings, Element, EasingData )
				end

				EasingData.LastUpdate = Time
			end

			if Easings:IsEmpty() then
				self.EasingProcesses:Remove( EasingHandler )
			end
		end
	end
end

local function Easer( Table, Name )
	return setmetatable( Table, { __tostring = function() return Name end } )
end

local Easers = {
	Fade = Easer( {
		Easer = function( self, Element, EasingData, Progress )
			SGUI.ColourLerp( EasingData.CurValue, EasingData.Start, Progress, EasingData.Diff )
		end,
		Setter = function( self, Element, Colour )
			if Element == self.Background then
				self:SetBackgroundColour( Colour )
			else
				Element:SetColor( Colour )
			end
		end,
		Getter = function( self, Element )
			return Element:GetColor()
		end
	}, "Fade" ),
	Alpha = Easer( {
		Init = function( self, Element, EasingData )
			EasingData.Colour = Element:GetColor()
		end,
		Easer = function( self, Element, EasingData, Progress )
			EasingData.CurValue = EasingData.Start + EasingData.Diff * Progress
			EasingData.Colour.a = EasingData.CurValue
		end,
		Setter = function( self, Element, Alpha, EasingData )
			EasingData.Colour.a = Alpha
			if Element == self.Background then
				self:SetBackgroundColour( EasingData.Colour )
			else
				Element:SetColor( EasingData.Colour )
			end
		end,
		Getter = function( self, Element )
			return Element:GetColor().a
		end
	}, "Alpha" ),
	AlphaMultiplier = Easer( {
		Easer = function( self, Element, EasingData, Progress )
			EasingData.CurValue = EasingData.Start + EasingData.Diff * Progress
		end,
		Setter = function( self, Element, AlphaMultiplier )
			self:SetAlphaMultiplier( AlphaMultiplier )
		end,
		Getter = function( self, Element )
			return self:GetAlphaMultiplier()
		end
	}, "AlphaMultiplier" ),
	Move = Easer( {
		Easer = function( self, Element, EasingData, Progress )
			local CurValue = EasingData.CurValue
			local Start = EasingData.Start
			local Diff = EasingData.Diff

			CurValue.x = Start.x + Diff.x * Progress
			CurValue.y = Start.y + Diff.y * Progress
		end,
		Setter = function( self, Element, Pos )
			if Element == self.Background then
				self:SetPos( Pos )
			else
				Element:SetPosition( Pos )
			end
		end,
		Getter = function( self, Element )
			return Element:GetPosition()
		end,
		OnComplete = function( self, Element, EasingData )
			if Element == self.Background then
				self:InvalidateMouseState()
			end
		end
	}, "Move" ),
	Size = Easer( {
		Setter = function( self, Element, Size )
			if Element == self.Background then
				self:SetSize( Size )
			else
				Element:SetSize( Size )
			end
		end,
		Getter = function( self, Element )
			return Element:GetSize()
		end,
		OnComplete = function( self, Element, EasingData )
			if Element == self.Background then
				self:InvalidateMouseState()
			end
		end
	}, "Size" ),
	Scale = Easer( {
		Setter = function( self, Element, Scale )
			Element:SetScale( Scale )
		end,
		Getter = function( self, Element )
			return Element:GetScale()
		end
	}, "Scale" )
}
Easers.Size.Easer = Easers.Move.Easer
Easers.Scale.Easer = Easers.Move.Easer

function ControlMeta:GetEasing( Type, Element )
	if not self.EasingProcesses then return end

	local Easers = self.EasingProcesses:Get( Easers[ Type ] )
	if not Easers then return end

	return Easers:Get( Element or self.Background )
end

function ControlMeta:StopEasing( Element, EasingHandler )
	if not self.EasingProcesses then return end

	local Easers = self.EasingProcesses:Get( EasingHandler )
	if not Easers then return end

	Element = Element or self.Background

	local EasingData = Easers:Get( Element )
	if EasingData and EasingHandler.OnComplete then
		EasingHandler.OnComplete( self, Element, EasingData )
	end

	Easers:Remove( Element )
end

function ControlMeta:StopEasingType( TypeName, Element )
	return self:StopEasing( Element, Easers[ TypeName ] )
end

local function AddEaseFunc( EasingData, EaseFunc, Power )
	EasingData.EaseFunc = EaseFunc or math.EaseOut
	EasingData.Power = Power or 3
end

do
	local function GetEaserForTransition( Transition )
		return Easers[ Transition.Type ] or Transition.Easer
	end

	--[[
		Adds a new easing transition to the control.

		Transitions are a table like the following:
		{
			-- The element the easing should apply to (if omitted, self.Background is used).
			Element = self.Background,

			-- The starting value (if omitted, the current value for the specified type is used).
			StartValue = self:GetPos(),

			-- The end value to ease towards.
			EndValue = self:GetPos() + Vector2( 100, 0 ),

			-- The time to wait (in seconds) from now until the transition should start (if omitted, no delay is applied).
			Delay = 0,

			-- How long (in seconds) to take to ease between the start and end values.
			Duration = 0.3,

			-- An optional callback that is executed once the transition is complete. It will be passed the control and
			-- the element that was transitioned.
			Callback = function( self, Element ) end,

			-- The type of easer to use (if using a standard easer)
			Type = "Move",

			-- A custom easer to use if "Type" is not specified.
			Easer = ...,

			-- The easing function to use (if omitted, math.EaseOut is used).
			EasingFunction = math.EaseOut,

			-- The power value to pass to the easing function (if omitted, 3 is used).
			EasingPower = 3
		}
	]]
	function ControlMeta:ApplyTransition( Transition )
		local EasingData = self:EaseValue(
			Transition.Element,
			Transition.StartValue,
			Transition.EndValue,
			Transition.Delay or 0,
			Transition.Duration,
			Transition.Callback,
			GetEaserForTransition( Transition )
		)
		AddEaseFunc( EasingData, Transition.EasingFunction, Transition.EasingPower )

		return EasingData
	end

	function ControlMeta:StopTransition( Transition )
		self:StopEasing( Transition.Element, GetEaserForTransition( Transition ) )
	end
end

--[[
	Sets an SGUI control to move from its current position.

	Inputs:
		1. Element to move, nil uses self.Background.
		2. Starting position, nil uses current position.
		3. Ending position.
		4. Delay in seconds to wait before moving.
		5. Duration of movement.
		6. Callback function to run once movement is complete.
		7. Easing function to use to perform movement, otherwise linear movement is used.
		8. Power to pass to the easing function.
]]
function ControlMeta:MoveTo( Element, Start, End, Delay, Duration, Callback, EaseFunc, Power )
	local EasingData = self:EaseValue( Element, Start, End, Delay, Duration, Callback,
		Easers.Move )
	AddEaseFunc( EasingData, EaseFunc, Power )

	return EasingData
end

function ControlMeta:StopMoving( Element )
	self:StopEasing( Element, Easers.Move )
end

--[[
	Fades an element from one colour to another.

	You can fade as many GUIItems in an SGUI control as you want at once.

	Inputs:
		1. GUIItem to fade.
		2. Starting colour.
		3. Final colour.
		4. Delay from when this is called to wait before starting the fade.
		5. Duration of the fade.
		6. Callback function to run once the fading has completed.
]]
function ControlMeta:FadeTo( Element, Start, End, Delay, Duration, Callback, EaseFunc, Power )
	local EasingData = self:EaseValue( Element, Start, End, Delay, Duration, Callback, Easers.Fade )
	AddEaseFunc( EasingData, EaseFunc, Power )

	return EasingData
end

function ControlMeta:StopFade( Element )
	self:StopEasing( Element, Easers.Fade )
end

function ControlMeta:AlphaTo( Element, Start, End, Delay, Duration, Callback, EaseFunc, Power )
	local EasingData = self:EaseValue( Element, Start, End, Delay, Duration, Callback, Easers.Alpha )
	AddEaseFunc( EasingData, EaseFunc, Power )

	return EasingData
end

function ControlMeta:StopAlpha( Element )
	self:StopEasing( Element, Easers.Alpha )
end

--[[
	Resizes an element from one size to another.

	Inputs:
		1. GUIItem to resize.
		2. Starting size, leave nil to use the element's current size.
		3. Ending size.
		4. Delay before resizing should start.
		5. Duration of resizing.
		6. Callback to run when resizing is complete.
		7. Optional easing function to use.
		8. Optional power to pass to the easing function.
]]
function ControlMeta:SizeTo( Element, Start, End, Delay, Duration, Callback, EaseFunc, Power )
	local EasingData = self:EaseValue( Element, Start, End, Delay, Duration, Callback,
		Easers.Size )
	AddEaseFunc( EasingData, EaseFunc, Power )

	return EasingData
end

function ControlMeta:StopResizing( Element )
	self:StopEasing( Element, Easers.Size )
end

SGUI.AddProperty( ControlMeta, "ActiveCol" )
SGUI.AddProperty( ControlMeta, "InactiveCol" )

do
	local function HandleHighlightOnVisibilityChange( self, IsVisible )
		if not IsVisible then
			self:SetHighlighted( false, true )
		else
			self:SetHighlighted( self:ShouldHighlight(), true )
		end
	end

	-- Basic highlight on mouse over handling.
	local function HandleHightlighting( self )
		if self:ShouldHighlight() then
			self:SetHighlighted( true )
		elseif self.Highlighted and not self.ForceHighlight then
			self:SetHighlighted( false )
		end
	end

	local function NoOpHighlighting() end

	ControlMeta.HandleHightlighting = NoOpHighlighting

	--[[
		Sets an SGUI control to highlight on mouse over automatically.

		Requires the values:
			self.ActiveCol - Colour when highlighted.
			self.InactiveCol - Colour when not highlighted.

		Will set the value:
			self.Highlighted - Will be true when highlighted.

		Only applies to the background.

		Inputs:
			1. Boolean should hightlight.
			2. Muliplier to the element's size when determining if the mouse is in the element.
	]]
	function ControlMeta:SetHighlightOnMouseOver( HighlightOnMouseOver, TextureMode )
		local WasHighlightOnMouseOver = self.HighlightOnMouseOver

		self.HighlightOnMouseOver = not not HighlightOnMouseOver

		if not WasHighlightOnMouseOver and self.HighlightOnMouseOver then
			self.HandleHightlighting = HandleHightlighting
			self:AddPropertyChangeListener( "IsVisible", HandleHighlightOnVisibilityChange )
		elseif WasHighlightOnMouseOver and not self.HighlightOnMouseOver then
			self.HandleHightlighting = NoOpHighlighting
			self:RemovePropertyChangeListener( "IsVisible", HandleHighlightOnVisibilityChange )
		end

		if not HighlightOnMouseOver then
			if not self.ForceHighlight then
				self:SetHighlighted( false, true )
				self:StopFade( self.Background )
			end

			self.TextureHighlight = TextureMode
		else
			self.TextureHighlight = TextureMode
			self:HandleHightlighting()
		end
	end
end

do
	local function ResetHoveringState( self )
		self.MouseHoverStart = nil

		if self.MouseHovered then
			self.MouseHovered = nil

			if self.OnLoseHover then
				self:OnLoseHover()
			end
		end
	end

	local function HandleVisibilityChange( self, IsVisible )
		if not IsVisible then
			ResetHoveringState( self )
		end
	end

	function ControlMeta:ListenForHoverEvents( OnHover, OnLoseHover )
		local OldOnHover = self.OnHover

		self.OnHover = OnHover
		self.OnLoseHover = OnLoseHover

		if not OldOnHover then
			self:AddPropertyChangeListener( "IsVisible", HandleVisibilityChange )
		end
	end

	function ControlMeta:ResetHoverEvents()
		self.OnHover = nil
		self.OnLoseHover = nil
		self:RemovePropertyChangeListener( "IsVisible", HandleVisibilityChange )
	end

	--[[
		Sets up a tooltip for the given element.
		This should work on any element without needing special code for it.

		Input: Text value to display as a tooltip, pass in nil to remove the tooltip.
	]]
	function ControlMeta:SetTooltip( Text )
		if Text == nil then
			self.TooltipText = nil
			self:ResetHoverEvents()
			self:HideTooltip()
			return
		end

		self.TooltipText = Text
		self:ListenForHoverEvents( self.ShowTooltip, self.HideTooltip )

		if SGUI.IsValid( self.Tooltip ) and not self.Tooltip.FadingOut then
			self.Tooltip:UpdateText( Text )
		end
	end

	--[[
		Resets the control's tooltip state, hiding any existing tooltip and resetting the hover delay.
	]]
	function ControlMeta:ResetTooltip( Text )
		self:HideTooltip()

		ResetHoveringState( self )

		self:SetTooltip( Text )
	end

	local DEFAULT_HOVER_TIME = 0.5
	function ControlMeta:HandleHovering( Time )
		if not self.OnHover then return end

		local MouseIn = self:HasMouseEntered() and self:GetIsVisible()

		-- If the mouse is in this object, then consider the object hovered.
		if MouseIn then
			if not self.MouseHoverStart then
				self.MouseHoverStart = Time
			else
				if Time - self.MouseHoverStart > ( self.HoverTime or DEFAULT_HOVER_TIME ) and not self.MouseHovered then
					self.MouseHovered = true

					local _, X, Y = self:MouseInCached()
					self:OnHover( X, Y )
				end
			end
		else
			ResetHoveringState( self )
		end
	end
end

function ControlMeta:HandleLayout( DeltaTime, Force )
	-- Do not attempt to perform layout operations if the element is currently not visible. Normally this is checked
	-- in Think(), but this method can also be called by a layout.
	if not Force and ( not self:GetIsVisible() or self:IsCroppedByParent() ) then return end

	-- Sometimes layout requires multiple passes to reach the final answer (e.g. if auto-wrapping text).
	-- Allow up to 5 iterations before stopping and leaving it for the next frame.
	for i = 1, 5 do
		if not self.LayoutIsInvalid then break end

		self.LayoutIsInvalid = false
		self:PerformLayout()
	end

	if self.Layout then
		-- Think after the control's layout as the control's layout invalidation may trigger the layout too.
		self.Layout:Think( DeltaTime )
	end
end

local function DoThink( self, DeltaTime )
	local Time = Clock()

	self:HandleEasing( Time, DeltaTime )

	-- Only handle easing when out of view (in case the easing is moving the element into view), everything else should
	-- wait for the element to come back into view.
	if self:IsCroppedByParent() then return false end

	self:HandleHovering( Time )
	self:HandleLayout( DeltaTime )
	self:HandleMouseState()

	return true
end

--[[
	Global update function. Called on client update.

	You must call this inside a control's custom Think function with:
		self.BaseClass.Think( self, DeltaTime )
	if you want to use MoveTo, FadeTo, SetHighlightOnMouseOver etc.

	Alternatively, call only the functions you want to use.
]]
function ControlMeta:Think( DeltaTime )
	DoThink( self, DeltaTime )
end

function ControlMeta:ThinkWithChildren( DeltaTime )
	if not self:GetIsVisible() then return end

	if DoThink( self, DeltaTime ) then
		self:CallOnChildren( "Think", DeltaTime )
	end
end

function ControlMeta:GetTooltipOffset( MouseX, MouseY, Tooltip )
	local SelfPos = self:GetScreenPos()

	local X = SelfPos.x + MouseX
	local Y = SelfPos.y + MouseY

	Y = Y - Tooltip:GetSize().y - 4

	return X, Y
end

function ControlMeta:ShowTooltip( MouseX, MouseY )
	local Tooltip = self.Tooltip
	if not SGUI.IsValid( Tooltip ) then
		Tooltip = SGUI:Create( "Tooltip" )
		Tooltip:SetAssociatedControl( self )

		-- As the Tooltip element is not a child of this element, the skin must be set manually.
		if self.PropagateSkin then
			Tooltip:SetSkin( self:GetSkin() )
		end
	end

	local W, H = SGUI.GetScreenSize()
	local Font
	local TextScale

	if H <= SGUI.ScreenHeight.Small then
		Font = Fonts.kAgencyFB_Tiny
	elseif H > SGUI.ScreenHeight.Normal and H <= SGUI.ScreenHeight.Large then
		Font = Fonts.kAgencyFB_Medium
	elseif H > SGUI.ScreenHeight.Large then
		Font = Fonts.kAgencyFB_Huge
		TextScale = Vector2( 0.5, 0.5 )
	end

	Tooltip:SetTextPadding( SGUI.Layout.Units.HighResScaled( 16 ):GetValue() )
	Tooltip:SetText( self.TooltipText, Font, TextScale )

	local X, Y = self:GetTooltipOffset( MouseX, MouseY, Tooltip )
	Tooltip:SetPos( Vector2( X, Y ) )
	Tooltip:FadeIn()

	self.Tooltip = Tooltip
end

do
	local function OnTooltipHidden( self )
		self.Tooltip = nil
	end

	function ControlMeta:HideTooltip()
		if not SGUI.IsValid( self.Tooltip ) then return end

		self.Tooltip:FadeOut( OnTooltipHidden, self )
	end
end

function ControlMeta:SetHighlighted( Highlighted, SkipAnim )
	if not not Highlighted == not not self.Highlighted then return end

	if Highlighted then
		self.Highlighted = true
		self:AddStylingState( "Highlighted" )

		if not self.TextureHighlight then
			if SkipAnim then
				self:StopFade( self.Background )
				self:SetBackgroundColour( self.ActiveCol )
				return
			end

			self:FadeTo( self.Background, self.InactiveCol, self.ActiveCol, 0, 0.1 )
		else
			self.Background:SetTexture( self.HighlightTexture )
		end
	else
		self.Highlighted = false
		self:RemoveStylingState( "Highlighted" )

		if not self.TextureHighlight then
			if SkipAnim then
				self:StopFade( self.Background )
				self:SetBackgroundColour( self.InactiveCol )
				return
			end

			self:FadeTo( self.Background, self.ActiveCol, self.InactiveCol, 0, 0.1 )
		else
			self.Background:SetTexture( self.Texture )
		end
	end
end

function ControlMeta:ShouldHighlight()
	return self:GetIsVisible() and self:HasMouseEntered()
end

function ControlMeta:SetForceHighlight( ForceHighlight, SkipAnim )
	self.ForceHighlight = ForceHighlight

	if ForceHighlight and not self.Highlighted then
		self:SetHighlighted( true, SkipAnim )
	elseif not ForceHighlight and self.Highlighted and not self:ShouldHighlight() then
		self:SetHighlighted( false, SkipAnim )
	end
end

function ControlMeta:OnMouseDown( Key, DoubleClick )
	if not self:GetIsVisible() then return end
	if not self:HasMouseEntered() then return end

	local Result, Child = self:CallOnChildren( "OnMouseDown", Key, DoubleClick )
	if Result ~= nil then return true, Child end
end

function ControlMeta:PlayerKeyPress( Key, Down )
	if not self:GetIsVisible() then return end

	if self:CallOnChildren( "PlayerKeyPress", Key, Down ) then
		return true
	end
end

function ControlMeta:PlayerType( Char )
	if not self:GetIsVisible() then return end

	if self:CallOnChildren( "PlayerType", Char ) then
		return true
	end
end

function ControlMeta:OnMouseWheel( Down )
	if not self:GetIsVisible() then return end

	local Result = self:CallOnChildren( "OnMouseWheel", Down )
	if Result ~= nil then return true end
end

function ControlMeta:HasMouseEntered()
	return self.MouseHasEntered
end

--[[
	Called when the mouse cursor has entered the control.

	The result of the MouseInControl method determines when this occurs.
]]
function ControlMeta:OnMouseEnter()

end

--[[
	Called when the mouse cursor has left the control.

	The result of the MouseInControl method determines when this occurs.
]]
function ControlMeta:OnMouseLeave()

end

do
	local function InvalidateWindowMouseState( Window, Now )
		Window:InvalidateMouseState( Now, true )
	end

	function ControlMeta:InvalidateMouseState( Now, SkipRecursion )
		self.MouseStateIsInvalid = true
		if Now then
			self:HandleMouseState()
		end

		-- If this element is a window, also invalidate the next window down (and so on recursively) to ensure that lower
		-- windows pick up on changes to mouse obstruction from higher windows.
		if not SkipRecursion and SGUI:IsWindow( self ) then
			SGUI:ForEachWindowBelow( self, InvalidateWindowMouseState, Now )
		end
	end
end

function ControlMeta:HandleMouseState()
	if not self.MouseStateIsInvalid or not SGUI.IsMouseVisible() then return end

	self:EvaluateMouseState()
	self:CallOnChildren( "OnMouseMove", false )
end

function ControlMeta:EvaluateMouseState()
	local Parent = self.Parent

	local CanMouseBeIn = false
	if Parent then
		-- If there's a parent element, the mouse can only be inside this element if it's also within the parent (as
		-- this element will only receive future mouse events if the mouse is within the parent).
		CanMouseBeIn = Parent.AlwaysInMouseFocus or Parent:HasMouseEntered()
	elseif SGUI:IsWindow( self ) then
		-- If there's no parent, and this is a window, then the mouse can only be inside if there isn't a higher window
		-- that's captured the mouse and thus is obstructing this element. Note that this branch should essentially
		-- be always the case if there's no parent, but it doesn't hurt to sanity check. Elements with no parent that
		-- are not a window should never receive mouse input.
		CanMouseBeIn = not SGUI:IsWindowFocusObstructed( self )
	end

	local IsMouseIn = CanMouseBeIn and self:MouseInCached()

	local StateChanged = false
	if IsMouseIn and not self.MouseHasEntered then
		StateChanged = true

		self.MouseHasEntered = true
		self:OnMouseEnter()
	elseif not IsMouseIn and self.MouseHasEntered then
		-- Need to let children see the mouse exit themselves too.
		StateChanged = true

		self.MouseHasEntered = false
		self:OnMouseLeave()
	end

	self:HandleHightlighting()
	self.MouseStateIsInvalid = false

	return IsMouseIn, StateChanged
end

function ControlMeta:OnMouseMove( Down )
	if not self:GetIsVisible() then return end

	self.__LastMouseMove = SGUI.FrameNumber()

	local IsMouseIn, StateChanged = self:EvaluateMouseState()
	if IsMouseIn or StateChanged then
		self:CallOnChildren( "OnMouseMove", Down )
	end
end

--[[
	Requests focus, for controls with keyboard input.
]]
function ControlMeta:RequestFocus()
	if not self.UsesKeyboardFocus then return end

	SGUI.NotifyFocusChange( self )
end

--[[
	Returns whether the current control has keyboard focus.
]]
function ControlMeta:HasFocus()
	return SGUI.FocusedControl == self
end

--[[
	Drops keyboard focus on the given element.
]]
function ControlMeta:LoseFocus()
	if not self:HasFocus() then return end

	SGUI.NotifyFocusChange()
end

--[[
	Returns whether the current object is still in use.
	Output: Boolean valid.
]]
function ControlMeta:IsValid()
	return SGUI.ActiveControls:Get( self ) ~= nil
end
