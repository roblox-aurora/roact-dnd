import Roact from "@rbxts/roact";
import "@rbxts/types";

export as namespace RoactDnD;
export = RoactDnD;

interface StatefulComponent<P> extends Roact.RenderablePropsClass<P> {}

interface FunctionalComponent<P> {
	(props: P): Roact.Element | undefined;
}

interface DragSourceWrapper<P> {
	new (props: P): {
		render(): Roact.Element | undefined;
	};
}

interface DragTargetWrapper<P> {
	new (props: P): {
		render(): Roact.Element | undefined;
	};
}

type DropId = string | number | symbol;

type IDragDropHandler<T extends GuiObject> = Roact.JsxObject<T> & {
	DropId: DropId;
	Ref?: (rbx: T) => void;
};

type IDropTarget<T extends GuiObject> = IDragDropHandler<T> & {
	DropId: DropId | Array<DropId>;

	/**
	 * An event that's called when a `DragSource` is successfully dropped onto this target
	 */
	TargetDropped: (Data: unknown) => void;

	/**
	 * The priority of this `DropTarget`.
	 *
	 * A target with a higher priority will be chosen if there are multiple `DropTarget`s in the same area.
	 */
	TargetPriority?: number;
};
type IDragSource<T extends GuiObject> = IDragDropHandler<T> & {
	/** The data that will be sent to the `DropTarget` if this `DragSource` successfully drops on this target */
	TargetData: unknown;

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
};

declare namespace RoactDnD {
	class DragDropContext {
		constructor(options?: unknown); // TODO: Options, eventually
		static Default: DragDropContext;
	}

	interface DragDropProviderProps {
		context?: DragDropContext;
	}

	class DragDropProvider extends Roact.Component<DragDropProviderProps> {
		constructor(props: DragDropProviderProps);
		public render(): Roact.Element;
	}

	// export function createDragSource<P, A extends unknown>(
	//   innerComponent: keyof CreatableInstances, // StatefulComponent<P>,
	//   options?: IDraggableOptions
	// ): DragSourceWrapper<P>;

	// export function createDragTarget<P, A extends unknown>(
	//     innerComponent: keyof CreatableInstances, // StatefulComponent<P>,
	//     onDragEnd: (data: A) => void,
	//     options?: IDraggableOptions
	// ): DragTargetWrapper<P>;

	class DragFrame extends Roact.Component<IDragSource<Frame>> {
		public render(): Roact.Element;
	}

	class DropFrame extends Roact.Component<IDropTarget<Frame>> {
		public render(): Roact.Element;
	}
}
