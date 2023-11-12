export type RoactDnDBinding = RoactBinding<GuiObject>

export type BindingSourceProps = {
	DropId: string,
	TargetData: unknown,
	DragEnd: (() -> ())?,
	DragBegin: (() -> ())?,
	OnDragging: (() -> ())?,
}

export type RoactBinding<T> = {
	getValue: (self: RoactBinding<T>) -> T?,
}
export type RoactBindingFunction<T> = (value: T | nil) -> ()

export type RoactElement = {}

export type RoactComponent<P, S, E> = {
	init: (self: RoactComponent<P, S, E>, props: P) -> (),
	render: (self: RoactComponent<P, S, E>) -> RoactElement,
	props: P,
	state: S,
} & E

export type RoactAnyComponent<P> = RoactComponent<P, any, any> | ((props: P) -> RoactElement) | string

type RoactComponentConstructor = {
	extend: <P>(self: RoactComponentConstructor, name: string) -> RoactComponent<P, any, any>,
}

export type RoactChildren = {
	__roact_children: never,
}
export type Roact = {
	createElement: (...any) -> RoactElement,
	createBinding: <T>(value: T) -> (RoactBinding<T>, RoactBindingFunction<T>),
	createFragment: (fragments: { [string]: RoactElement }) -> RoactElement,
	Ref: any,
	Portal: any,
	mount: any,
	None: any,
	oneChild: (element: RoactElement) -> RoactElement,
	Children: RoactChildren,
	Component: RoactComponentConstructor,
	PureComponent: RoactComponentConstructor,
}

export type DragDropContextActions =
	{ type: "DROP/TARGET", dropId: string, source: RoactDnDBinding, target: RoactDnDBinding, data: unknown }
	| { type: "DRAG/BEGIN", source: RoactDnDBinding }
	| { type: "DRAG/END", source: RoactDnDBinding, dropped: boolean }
	| { type: "REGISTRY/ADD_SOURCE", source: RoactDnDBinding, props: DragSourceProps }
	| { type: "REGISTRY/ADD_TARGET", target: RoactDnDBinding, props: DropTargetProps }
	| { type: "REGISTRY/REMOVE_TARGET", target: RoactDnDBinding }
	| { type: "REGISTRY/REMOVE_SOURCE", source: RoactDnDBinding }

type Binding = { __nominal_Binding: nil }

export type RoactType = {
	Binding: Binding,
	of: (value: unknown) -> Binding,
}

export type Target = { Binding: RoactDnDBinding, Target: RoactDnDBinding, OnDrop: (() -> ())?, Priority: number? }

export type DragSourceProps = {
	DropId: string,
	TargetData: unknown,
	DragController: "Snapdragon" | "Legacy",
	CanDrag: ((targetData: unknown) -> boolean)?,
	DragBegin: (() -> ())?,
	DragEnd: ((hasDropTarget: boolean) -> ())?,
	OnDragging: (() -> ())?,
	IsDragModal: boolean?,
	DropResetsPosition: boolean?,
	DragConstraint: ("ViewportIgnoreInset" | "Viewport" | "None")?,

	Position: UDim2,
}

export type DropTargetProps = {
	[RoactChildren]: { RoactElement },

	DropId: string,

	TargetDropped: (targetData: unknown) -> (),
	CanDrop: ((targetData: unknown) -> boolean)?,
	TargetHover: ((targetData: unknown, component: Instance) -> boolean)?,
	TargetPriority: number?,
}

export type Signal<T> = {
	Connect: (self: Signal<T>, callback: (value: T) -> ()) -> (),
	Fire: (...T) -> (),
}

export type SnapdragonController = {
	Destroy: (self: SnapdragonController) -> (),
	DragBegan: Signal<{
		AbsolutePosition: Vector2,
		InputPosition: UDim2,
		GuiPosition: UDim2,
	}>,
}

return nil
