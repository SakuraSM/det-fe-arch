import { type FC, useCallback, useState } from 'react'

const COMPONENT_STATES = {
  IDLE: 'idle',
  LOADING: 'loading',
  ERROR: 'error',
} as const

type ComponentState = (typeof COMPONENT_STATES)[keyof typeof COMPONENT_STATES]

interface ComponentNameProps {
  label?: string
  onAction?: () => void
}

const DEFAULT_BUTTON_LABEL = '操作'

const ComponentName: FC<ComponentNameProps> = ({
  label = DEFAULT_BUTTON_LABEL,
  onAction,
}) => {
  const [componentState, setComponentState] = useState<ComponentState>(COMPONENT_STATES.IDLE)

  const handleAction = useCallback((): void => {
    setComponentState(COMPONENT_STATES.LOADING)
    onAction?.()
    setComponentState(COMPONENT_STATES.IDLE)
  }, [onAction])

  const isLoading = componentState === COMPONENT_STATES.LOADING

  return (
    <section aria-label="ComponentName">
      <button type="button" onClick={handleAction} disabled={isLoading}>
        {label}
      </button>
    </section>
  )
}

export default ComponentName
