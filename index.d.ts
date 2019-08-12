import Roact from "@rbxts/roact";
import "@rbxts/types";

export as namespace RoactDnD;
export = RoactDnD;

interface DroppableWrapperProps {
  dropId: string;
  onDragEnd?: () => void;
}

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

interface IDraggableOptions {
  snap?: boolean;
  snapIgnoresOffset?: boolean;
}

type IDragDropTarget<T extends Instance> = Roact.JsxIntrinsic<T> & {
  DropId: string | number | symbol;
  Ref?: (rbx: T) => void;
};

type IDropTarget<T extends Instance> = IDragDropTarget<T> & {
  TargetDropped: (Data: unknown) => void;
}
type IDragTarget<T extends Instance> = IDragDropTarget<T> & {
  TargetData: unknown;
}

declare namespace RoactDnD {
  // class DroppableWrapper extends Roact.Component<DroppableWrapperProps> {
  //   constructor(props: DroppableWrapperProps);
  //   public render(): Roact.Element;
  // }

  // export function createDragSource<P, A extends unknown>(
  //   innerComponent: keyof CreatableInstances, // StatefulComponent<P>,
  //   options?: IDraggableOptions
  // ): DragSourceWrapper<P>;

  // export function createDragTarget<P, A extends unknown>(
  //     innerComponent: StatefulComponent<P>,
  //     onDragEnd: (data: A) => void,
  //     options?: IDraggableOptions
  // ): DragTargetWrapper<P>;

  class DragFrame extends Roact.Component<IDragTarget<Frame>> {
    public render(): Roact.Element;
  }

  class DropFrame extends Roact.Component<IDropTarget<Frame>> {
    public render(): Roact.Element;
  }
}
