import Roact from "@rbxts/roact";
import "@rbxts/types";

export as namespace RoactDnD;
export = RoactDnD;

type DropId = string | number | symbol;

interface IDragDropHandler<DropIdTypes, T extends Instance> {
	DropId: DropIdTypes;
	Ref?: (rbx: T) => void;
}

interface IDropTarget<T extends GuiObject, TData = unknown>
	extends IDragDropHandler<DropId | Array<DropId>, T> {
	/**
	 * An event that's called when a `DragSource` is successfully dropped onto this target
	 * @param targetData the data of the drag target that was dropped
	 */
	TargetDropped: (targetData: unknown) => void;

	/**
	 * Controls whether or not items can be dropped on this target
	 * @param targetData The target data of the dropping item
	 */
	CanDrop?: (targetData: unknown) => boolean;

	/**
	 * Called when an item hovers over a component
	 * @param targetData The target data of the hovering item
	 * @param component The target component of the hovering item
	 */
	TargetHover?: (targetData: unknown, component: Instance) => boolean;

	/**
	 * The priority of this `DropTarget`.
	 *
	 * A target with a higher priority will be chosen if there are multiple `DropTarget`s in the same area.
	 */
	TargetPriority?: number;
}

interface IDragSource<T extends GuiObject, TData = unknown> extends IDragDropHandler<DropId, T> {
	/** The data that will be sent to the `DropTarget` if this `DragSource` successfully drops on this target */
	TargetData: TData;

	/**
	 * Controls whether or not this item can be dragged
	 * @param targetData The target data of this item
	 */
	CanDrag?: (targetData: TData) => boolean;

	/**
	 * Called when the drag begins
	 */
	DragBegin?: () => void;

	/**
	 * Called when the drag ends
	 */
	DragEnd?: (hasDropTarget: boolean) => void;

	/**
	 * Will render the dragging as a modal (useful for having it on top of everything!)
	 * @deprecated
	 */
	IsDragModal?: boolean;

	/**
	 * Changes the dragging behaviour of the drag source.
	 * 
	 * - Snapdragon - Uses `Snapdragon`, which is modal-only
	 * - Legacy - Will use the legacy drag controller, which also uses `IsDragModal`
	 */
	DragController?: "Legacy" | "Snapdragon";

	/**
	 * How the dragging is constrained
	 *
	 * `None` - There is no limit to where it can be dragged
	 *
	 * `Viewport` - The instance can only be dragged within the viewport itself
	 *
	 * `ViewportIgnoreInset` - The instance can be dragged within the viewport as well as the inset area of the topbar
	 */
	DragConstraint?: "ViewportIgnoreInset" | "Viewport" | "None";

	/**
	 * If true, will reset the position of the DragTarget's instance when dragging stops
	 */
	DropResetsPosition?: boolean;
}

interface Action<A = any> {
	type: A;
}

declare namespace RoactDnD {
	class DragDropContext {
		constructor(options?: unknown); // TODO: Options, eventually
		static Default: DragDropContext;

		public dispatch(action: Action): void;
	}

	interface DragDropProviderProps {
		context?: DragDropContext;
	}

	class DragDropProvider extends Roact.Component<DragDropProviderProps> {
		constructor(props: DragDropProviderProps);
		public render(): Roact.Element;
	}

	class DragFrame extends Roact.Component<
		IDragSource<Frame> & Roact.JsxObject<Frame>
	> {
		public render(): Roact.Element;
	}

	class DropFrame extends Roact.Component<
		IDropTarget<Frame> & Roact.JsxObject<Frame>
	> {
		public render(): Roact.Element;
	}

	class DragImageButton<TData> extends Roact.Component<
		IDragSource<ImageButton, TData> & Roact.JsxObject<ImageButton>
	> {
		public render(): Roact.Element;
	}
}
