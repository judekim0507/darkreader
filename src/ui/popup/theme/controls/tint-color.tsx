import {m} from 'malevic';

import {ColorPicker} from '../../../controls';

import ThemeControl from './theme-control';

interface TintColorEditorProps {
    value: string;
    onChange: (value: string) => void;
    canReset: boolean;
    onReset: () => void;
}

export default function TintColorEditor(props: TintColorEditorProps) {
    return (
        <ThemeControl label="Tint Color">
            <ColorPicker
                color={props.value || '#3b82f6'}
                onChange={props.onChange}
                canReset={props.canReset}
                onReset={props.onReset}
            />
        </ThemeControl>
    );
}
