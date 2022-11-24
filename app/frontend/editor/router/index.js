import Vue from 'vue'
import VueRouter from 'vue-router'
import routes from './routes'
import store from '@/store'
import { hasAnyChanged } from '@/misc/utils'

Vue.use(VueRouter)

const router = new VueRouter({
  mode: 'history',
  base: window.baseUrl,
  routes,
})

router.beforeEach((to, from, next) => {
  // When an user wants to edit another page or to edit the current page
  // in a different locale, the router detects it and dispatch the new
  // page information to the Vuex store.
  // Important: we don't do that at startup because we already have the current page
  // and locale in the state.
  if (hasAnyChanged(to.params, from.params, 'pageId', 'locale'))
    store.dispatch('editPage', {
      id: to.params.pageId,
      locale: to.params.locale,
    })

  next()
})

export default router
