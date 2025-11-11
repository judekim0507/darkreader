import {m} from 'malevic';

import {Slider} from '../../../controls';

import {formatPercent} from './format';
import ThemeControl from './theme-control';

export default function TintStrength(props: {value: number; onChange: (v: number) => void}) {
    return (
        <ThemeControl label="Tint Strength">
            <Slider
                value={props.value}
                min={0}
                max={100}
                step={1}
                formatValue={formatPercent}
                onChange={props.onChange}
            />
        </ThemeControl>
    );
}
